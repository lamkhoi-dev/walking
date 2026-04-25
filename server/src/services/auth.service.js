const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Company = require('../models/Company');
const Report = require('../models/Report');
const UserSettings = require('../models/UserSettings');
const StepRecord = require('../models/StepRecord');
const Group = require('../models/Group');
const config = require('../config/env');
const generateCompanyCode = require('../utils/generateCompanyCode');
const logger = require('../utils/logger');

class AuthService {
  /**
   * Generate JWT tokens
   */
  generateTokens(userId) {
    const accessToken = jwt.sign(
      { id: userId },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );
    const refreshToken = jwt.sign(
      { id: userId },
      config.jwt.refreshSecret,
      { expiresIn: config.jwt.refreshExpiresIn }
    );
    return { accessToken, refreshToken };
  }

  /**
   * Register a new member user
   */
  async registerUser({ email, phone, password, fullName, companyCode }) {
    // Validate: must have email or phone
    if (!email && !phone) {
      const err = new Error('Email hoặc số điện thoại là bắt buộc');
      err.statusCode = 422;
      throw err;
    }

    // Find company by code (OPTIONAL)
    let company = null;
    if (companyCode) {
      company = await Company.findOne({ code: companyCode.toUpperCase() });
      if (!company) {
        const err = new Error('Mã công ty không tồn tại');
        err.statusCode = 404;
        throw err;
      }

      if (company.status !== 'approved') {
        const err = new Error('Công ty chưa được phê duyệt');
        err.statusCode = 400;
        throw err;
      }
    }

    // Check email/phone uniqueness
    if (email) {
      const existingEmail = await User.findOne({ email });
      if (existingEmail) {
        const err = new Error('Email đã được sử dụng');
        err.statusCode = 409;
        throw err;
      }
    }

    if (phone) {
      const existingPhone = await User.findOne({ phone });
      if (existingPhone) {
        const err = new Error('Số điện thoại đã được sử dụng');
        err.statusCode = 409;
        throw err;
      }
    }

    // Create user
    const user = await User.create({
      email: email || undefined,
      phone: phone || undefined,
      password,
      fullName,
      role: 'member',
      companyId: company?._id || undefined,
      companyCode: company?.code || undefined,
      acceptedTermsAt: new Date(),
    });

    // Update company member count (only if company exists)
    if (company) {
      await Company.findByIdAndUpdate(company._id, {
        $inc: { totalMembers: 1 },
      });
    }

    // Generate tokens
    const tokens = this.generateTokens(user._id);

    logger.info(`New member registered: ${user.fullName}${company ? ` (${company.name})` : ''}`);

    return {
      user: user.toJSON(),
      company: company
        ? {
            _id: company._id,
            name: company.name,
            status: company.status,
            code: company.code,
          }
        : null,
      ...tokens,
    };
  }

  /**
   * Register a new company with admin user
   */
  async registerCompany({
    companyName,
    email,
    phone,
    address,
    description,
    adminEmail,
    adminPassword,
    adminFullName,
  }) {
    // Check company email uniqueness
    const existingCompany = await Company.findOne({ email });
    if (existingCompany) {
      const err = new Error('Email công ty đã được sử dụng');
      err.statusCode = 409;
      throw err;
    }

    // Check admin email uniqueness
    const existingAdmin = await User.findOne({ email: adminEmail });
    if (existingAdmin) {
      const err = new Error('Email admin đã được sử dụng');
      err.statusCode = 409;
      throw err;
    }

    // Create company (pending, no code yet)
    const company = await Company.create({
      name: companyName,
      email,
      phone: phone || undefined,
      address: address || undefined,
      description: description || undefined,
      status: 'pending',
    });

    // Create admin user
    const user = await User.create({
      email: adminEmail,
      password: adminPassword,
      fullName: adminFullName,
      role: 'company_admin',
      companyId: company._id,
    });

    // Link admin to company
    company.adminId = user._id;
    await company.save();

    logger.info(`New company registered: ${companyName} by ${adminFullName}`);

    return {
      company: company.toJSON(),
      user: user.toJSON(),
    };
  }

  /**
   * Login user
   */
  async login({ identifier, password }) {
    // Find user by email or phone
    const user = await User.findOne({
      $or: [
        { email: identifier.toLowerCase() },
        { phone: identifier },
      ],
    }).select('+password');

    if (!user) {
      const err = new Error('Email/SĐT hoặc mật khẩu không đúng');
      err.statusCode = 401;
      throw err;
    }

    if (!user.isActive) {
      const err = new Error('Tài khoản đã bị vô hiệu hóa');
      err.statusCode = 401;
      throw err;
    }

    // Compare password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      const err = new Error('Email/SĐT hoặc mật khẩu không đúng');
      err.statusCode = 401;
      throw err;
    }

    // Get company info if applicable
    let company = null;
    if (user.role === 'company_admin' || user.role === 'member') {
      company = await Company.findById(user.companyId).select(
        '_id name status code totalMembers'
      );
    }

    // Generate tokens
    const tokens = this.generateTokens(user._id);

    // Update lastOnline
    user.lastOnline = new Date();
    await user.save({ validateBeforeSave: false });

    logger.info(`User logged in: ${user.fullName}`);

    return {
      user: user.toJSON(),
      company,
      ...tokens,
    };
  }

  /**
   * Refresh access token
   */
  async refreshToken({ refreshToken }) {
    if (!refreshToken) {
      const err = new Error('Refresh token là bắt buộc');
      err.statusCode = 400;
      throw err;
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, config.jwt.refreshSecret);
    } catch {
      const err = new Error('Refresh token không hợp lệ hoặc hết hạn');
      err.statusCode = 401;
      throw err;
    }

    const user = await User.findById(decoded.id);
    if (!user || !user.isActive) {
      const err = new Error('Người dùng không tồn tại');
      err.statusCode = 401;
      throw err;
    }

    // Generate new access token only
    const accessToken = jwt.sign(
      { id: user._id },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );

    return { accessToken };
  }

  /**
   * Get user profile with company info
   */
  async getMe(userId) {
    const user = await User.findById(userId);
    if (!user) {
      const err = new Error('Người dùng không tồn tại');
      err.statusCode = 404;
      throw err;
    }

    let company = null;
    if (user.companyId) {
      company = await Company.findById(user.companyId).select(
        '_id name status code logo totalMembers'
      );
    }

    return {
      user: user.toJSON(),
      company,
    };
  }

  /**
   * Soft-delete user account
   */
  async softDeleteAccount(userId, password) {
    const user = await User.findById(userId).select('+password');
    if (!user) {
      const err = new Error('Người dùng không tồn tại');
      err.statusCode = 404;
      throw err;
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      const err = new Error('Mật khẩu không đúng');
      err.statusCode = 401;
      throw err;
    }

    // Soft-delete: deactivate + clear personal data
    await User.findByIdAndUpdate(userId, {
      $set: {
        isActive: false,
        deletedAt: new Date(),
        fullName: 'Tài khoản đã xóa',
        avatar: null,
        deviceToken: null,
        blockedUsers: [],
      },
      $unset: {
        email: 1,
        phone: 1,
      }
    });

    // Clean up related data
    await Promise.all([
      UserSettings.deleteOne({ userId }),
      StepRecord.deleteMany({ userId }),
      Group.updateMany({ members: userId }, { $pull: { members: userId } }),
    ]);

    logger.info(`Account soft-deleted: ${userId}`);
    return { success: true };
  }

  /**
   * Block a user
   */
  async blockUser(blockerId, targetId) {
    if (blockerId.toString() === targetId.toString()) {
      const err = new Error('Không thể tự chặn chính mình');
      err.statusCode = 400;
      throw err;
    }

    await User.findByIdAndUpdate(blockerId, {
      $addToSet: { blockedUsers: targetId },
    });

    // Auto-create report
    try {
      await Report.create({
        reporterId: blockerId,
        targetType: 'user',
        targetId,
        reason: 'harassment',
      });
    } catch (e) {
      // Ignore duplicate report error
    }

    logger.info(`User ${blockerId} blocked ${targetId}`);
    return { success: true };
  }

  /**
   * Unblock a user
   */
  async unblockUser(blockerId, targetId) {
    await User.findByIdAndUpdate(blockerId, {
      $pull: { blockedUsers: targetId },
    });
    return { success: true };
  }

  /**
   * Get list of blocked users
   */
  async getBlockedUsers(userId) {
    const user = await User.findById(userId)
      .populate('blockedUsers', 'fullName avatar')
      .lean();
    return user?.blockedUsers || [];
  }
}

module.exports = new AuthService();
