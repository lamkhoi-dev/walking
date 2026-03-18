const authService = require('../services/auth.service');
const stepService = require('../services/step.service');
const User = require('../models/User');
const { success, error } = require('../utils/response');

/**
 * Register a new member user
 * POST /api/v1/auth/register
 */
const register = async (req, res, next) => {
  try {
    const result = await authService.registerUser(req.body);
    return success(res, 201, 'Đăng ký thành công', result);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * Register a new company with admin
 * POST /api/v1/auth/register-company
 */
const registerCompany = async (req, res, next) => {
  try {
    const result = await authService.registerCompany(req.body);
    return success(res, 201, 'Đăng ký công ty thành công. Vui lòng chờ phê duyệt.', result);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * Login user
 * POST /api/v1/auth/login
 */
const login = async (req, res, next) => {
  try {
    const result = await authService.login(req.body);
    return success(res, 200, 'Đăng nhập thành công', result);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * Refresh access token
 * POST /api/v1/auth/refresh-token
 */
const refreshToken = async (req, res, next) => {
  try {
    const result = await authService.refreshToken(req.body);
    return success(res, 200, 'Token đã được làm mới', result);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * Logout user (client-side token removal)
 * POST /api/v1/auth/logout
 */
const logout = async (req, res) => {
  return success(res, 200, 'Đăng xuất thành công');
};

/**
 * Get current user profile
 * GET /api/v1/auth/me
 */
const getMe = async (req, res, next) => {
  try {
    const result = await authService.getMe(req.user._id);
    return success(res, 200, 'Thành công', result);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * Update current user profile
 * PUT /api/v1/auth/me
 */
const updateMe = async (req, res, next) => {
  try {
    const { fullName, avatar } = req.body;
    const userId = req.user._id;

    const updateData = {};
    if (fullName && fullName.trim()) {
      updateData.fullName = fullName.trim();
    }
    if (avatar !== undefined) {
      updateData.avatar = avatar;
    }

    if (Object.keys(updateData).length === 0) {
      return error(res, 400, 'Không có dữ liệu để cập nhật');
    }

    const user = await User.findByIdAndUpdate(
      userId,
      { $set: updateData },
      { new: true }
    ).lean();

    if (!user) {
      return error(res, 404, 'Không tìm thấy người dùng');
    }

    return success(res, 200, 'Cập nhật thành công', user);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * Get personal statistics
 * GET /api/v1/auth/me/stats
 */
const getMyStats = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const stats = await stepService.getStats(userId);
    
    // Add all-time stats
    const StepRecord = require('../models/StepRecord');
    const allTimeRecords = await StepRecord.find({ userId }).lean();
    
    const allTimeTotal = allTimeRecords.reduce((sum, r) => sum + (r.steps || 0), 0);
    const bestDay = allTimeRecords.reduce((best, r) => 
      (r.steps || 0) > (best?.steps || 0) ? r : best, null);
    
    // Calculate streak
    const sortedRecords = allTimeRecords
      .sort((a, b) => b.date.localeCompare(a.date));
    
    let streak = 0;
    const today = new Date().toISOString().split('T')[0];
    let checkDate = today;
    
    for (const record of sortedRecords) {
      if (record.date === checkDate && record.steps > 0) {
        streak++;
        // Move to previous day
        const d = new Date(checkDate);
        d.setDate(d.getDate() - 1);
        checkDate = d.toISOString().split('T')[0];
      } else if (record.date < checkDate) {
        break;
      }
    }

    return success(res, 200, 'Thống kê cá nhân', {
      ...stats,
      allTime: {
        totalSteps: allTimeTotal,
        totalDistance: Math.round(allTimeTotal * 0.762),
        totalCalories: Math.round(allTimeTotal * 0.04 * 100) / 100,
        daysTracked: allTimeRecords.length,
        bestDay: bestDay ? {
          date: bestDay.date,
          steps: bestDay.steps,
        } : null,
      },
      streak,
    });
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * Change password
 * PUT /api/v1/auth/change-password
 */
const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user._id;

    if (!currentPassword || !newPassword) {
      return error(res, 400, 'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới');
    }

    if (newPassword.length < 6) {
      return error(res, 400, 'Mật khẩu mới phải có ít nhất 6 ký tự');
    }

    // Fetch user with password field
    const user = await User.findById(userId).select('+password');
    if (!user) {
      return error(res, 404, 'Không tìm thấy người dùng');
    }

    // Verify current password
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return error(res, 401, 'Mật khẩu hiện tại không đúng');
    }

    // Update password (pre-save hook will hash it)
    user.password = newPassword;
    await user.save();

    return success(res, 200, 'Đổi mật khẩu thành công');
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

module.exports = {
  register,
  registerCompany,
  login,
  refreshToken,
  logout,
  getMe,
  updateMe,
  getMyStats,
  changePassword,
};
