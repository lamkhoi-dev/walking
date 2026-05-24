const Company = require('../models/Company');
const User = require('../models/User');
const { success, error } = require('../utils/response');
const generateCompanyCode = require('../utils/generateCompanyCode');
const escapeRegex = require('../utils/escapeRegex');

/**
 * GET /admin/companies
 * List companies with pagination, filter by status, search by name
 */
const getCompanies = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      search,
    } = req.query;

    const pageNum = Math.max(1, parseInt(page, 10));
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10)));
    const skip = (pageNum - 1) * limitNum;

    // Build filter
    const filter = {};
    if (status && ['pending', 'approved', 'rejected', 'suspended'].includes(status)) {
      filter.status = status;
    }
    if (search) {
      filter.name = { $regex: escapeRegex(search), $options: 'i' };
    }

    const [companies, total] = await Promise.all([
      Company.find(filter)
        .populate('adminId', 'fullName email phone')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Company.countDocuments(filter),
    ]);

    const totalPages = Math.ceil(total / limitNum);

    return success(res, 200, 'Lấy danh sách công ty thành công', companies, {
      page: pageNum,
      limit: limitNum,
      total,
      totalPages,
    });
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * GET /admin/companies/:id
 * Get company detail by ID with admin info & member count
 */
const getCompanyById = async (req, res) => {
  try {
    const { id } = req.params;

    const company = await Company.findById(id)
      .populate('adminId', 'fullName email phone avatar')
      .lean();

    if (!company) {
      return error(res, 404, 'Không tìm thấy công ty');
    }

    // Count actual members in this company
    const memberCount = await User.countDocuments({
      companyId: id,
      role: { $in: ['company_admin', 'member'] },
    });

    return success(res, 200, 'Lấy thông tin công ty thành công', {
      ...company,
      memberCount,
    });
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * PUT /admin/companies/:id/approve
 * Approve a pending company — generates company code
 */
const approveCompany = async (req, res) => {
  try {
    const { id } = req.params;

    const company = await Company.findById(id);
    if (!company) {
      return error(res, 404, 'Không tìm thấy công ty');
    }

    if (company.status !== 'pending') {
      return error(res, 400, `Không thể phê duyệt công ty có trạng thái "${company.status}"`);
    }

    // Generate unique company code
    let code;
    let isUnique = false;
    let attempts = 0;
    while (!isUnique && attempts < 10) {
      code = generateCompanyCode();
      const existing = await Company.findOne({ code });
      if (!existing) {
        isUnique = true;
      }
      attempts++;
    }

    if (!isUnique) {
      return error(res, 500, 'Không thể tạo mã công ty, vui lòng thử lại');
    }

    company.status = 'approved';
    company.code = code;
    await company.save();

    const populated = await Company.findById(company._id)
      .populate('adminId', 'fullName email phone')
      .lean();

    return success(res, 200, 'Phê duyệt công ty thành công', populated);
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * PUT /admin/companies/:id/reject
 * Reject a pending company
 */
const rejectCompany = async (req, res) => {
  try {
    const { id } = req.params;

    const company = await Company.findById(id);
    if (!company) {
      return error(res, 404, 'Không tìm thấy công ty');
    }

    if (company.status !== 'pending') {
      return error(res, 400, `Không thể từ chối công ty có trạng thái "${company.status}"`);
    }

    company.status = 'rejected';
    await company.save();

    const populated = await Company.findById(company._id)
      .populate('adminId', 'fullName email phone')
      .lean();

    return success(res, 200, 'Từ chối công ty thành công', populated);
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * PUT /admin/companies/:id/suspend
 * Suspend an approved company
 */
const suspendCompany = async (req, res) => {
  try {
    const { id } = req.params;

    const company = await Company.findById(id);
    if (!company) {
      return error(res, 404, 'Không tìm thấy công ty');
    }

    if (company.status !== 'approved') {
      return error(res, 400, `Không thể tạm ngưng công ty có trạng thái "${company.status}"`);
    }

    company.status = 'suspended';
    await company.save();

    const populated = await Company.findById(company._id)
      .populate('adminId', 'fullName email phone')
      .lean();

    return success(res, 200, 'Tạm ngưng công ty thành công', populated);
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * PUT /admin/companies/:id/reactivate
 * Reactivate a suspended company back to approved
 */
const reactivateCompany = async (req, res) => {
  try {
    const { id } = req.params;

    const company = await Company.findById(id);
    if (!company) {
      return error(res, 404, 'Không tìm thấy công ty');
    }

    if (company.status !== 'suspended') {
      return error(res, 400, `Không thể khôi phục công ty có trạng thái "${company.status}"`);
    }

    company.status = 'approved';
    await company.save();

    const populated = await Company.findById(company._id)
      .populate('adminId', 'fullName email phone')
      .lean();

    return success(res, 200, 'Khôi phục công ty thành công', populated);
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * GET /admin/stats
 * Dashboard statistics
 */
const getStats = async (req, res) => {
  try {
    const [
      totalCompanies,
      pendingCompanies,
      approvedCompanies,
      rejectedCompanies,
      suspendedCompanies,
      totalUsers,
      activeUsers,
    ] = await Promise.all([
      Company.countDocuments(),
      Company.countDocuments({ status: 'pending' }),
      Company.countDocuments({ status: 'approved' }),
      Company.countDocuments({ status: 'rejected' }),
      Company.countDocuments({ status: 'suspended' }),
      User.countDocuments({ role: { $ne: 'super_admin' } }),
      User.countDocuments({ role: { $ne: 'super_admin' }, isActive: true }),
    ]);

    return success(res, 200, 'Lấy thống kê thành công', {
      companies: {
        total: totalCompanies,
        pending: pendingCompanies,
        approved: approvedCompanies,
        rejected: rejectedCompanies,
        suspended: suspendedCompanies,
      },
      users: {
        total: totalUsers,
        active: activeUsers,
      },
    });
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * GET /admin/users
 * List users with pagination, filter by role/company/active, search by name/email/phone
 */
const getUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, role, companyId, isActive, search } = req.query;

    const pageNum = Math.max(1, parseInt(page, 10));
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10)));
    const skip = (pageNum - 1) * limitNum;

    const filter = { role: { $ne: 'super_admin' } };

    if (role && ['company_admin', 'member'].includes(role)) {
      filter.role = role;
    }
    if (companyId) {
      filter.companyId = companyId;
    }
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }
    if (search) {
      const escapedSearch = escapeRegex(search);
      filter.$or = [
        { fullName: { $regex: escapedSearch, $options: 'i' } },
        { email: { $regex: escapedSearch, $options: 'i' } },
        { phone: { $regex: escapedSearch, $options: 'i' } },
      ];
    }

    const [users, total] = await Promise.all([
      User.find(filter)
        .select('-password')
        .populate('companyId', 'name code status')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      User.countDocuments(filter),
    ]);

    return success(res, 200, 'Lấy danh sách người dùng thành công', users, {
      page: pageNum,
      limit: limitNum,
      total,
      totalPages: Math.ceil(total / limitNum),
    });
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * GET /admin/users/:id
 * Get user detail with company info
 */
const getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('-password')
      .populate('companyId', 'name code status email phone adminId')
      .lean();

    if (!user) {
      return error(res, 404, 'Không tìm thấy người dùng');
    }

    return success(res, 200, 'Lấy thông tin người dùng thành công', user);
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * PUT /admin/users/:id/role
 * Update user role (company_admin ↔ member)
 * Body: { role: 'company_admin' | 'member' }
 */
const updateUserRole = async (req, res) => {
  try {
    const { role: newRole } = req.body;

    if (!['company_admin', 'member'].includes(newRole)) {
      return error(res, 400, 'Role không hợp lệ. Chỉ hỗ trợ: company_admin, member');
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return error(res, 404, 'Không tìm thấy người dùng');
    }

    if (user.role === 'super_admin') {
      return error(res, 403, 'Không thể thay đổi role của super_admin');
    }

    if (user.role === newRole) {
      return error(res, 400, `Người dùng đã có role "${newRole}"`);
    }

    // If promoting to company_admin, check if company already has one
    if (newRole === 'company_admin' && user.companyId) {
      const existingAdmin = await User.findOne({
        companyId: user.companyId,
        role: 'company_admin',
        _id: { $ne: user._id },
      });

      if (existingAdmin) {
        // Transfer: demote old admin to member
        existingAdmin.role = 'member';
        await existingAdmin.save();

        // Also update Company.adminId
        await Company.findByIdAndUpdate(user.companyId, { adminId: user._id });
      }
    }

    // If demoting from company_admin, update Company.adminId to null
    if (user.role === 'company_admin' && newRole === 'member' && user.companyId) {
      await Company.findByIdAndUpdate(user.companyId, { adminId: null });
    }

    const oldRole = user.role;
    user.role = newRole;
    await user.save();

    const populated = await User.findById(user._id)
      .select('-password')
      .populate('companyId', 'name code status')
      .lean();

    return success(res, 200, `Đã đổi role từ "${oldRole}" → "${newRole}"`, populated);
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

/**
 * PUT /admin/users/:id/toggle-active
 * Toggle user isActive (activate/deactivate)
 */
const toggleUserActive = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return error(res, 404, 'Không tìm thấy người dùng');
    }

    if (user.role === 'super_admin') {
      return error(res, 403, 'Không thể vô hiệu hóa super_admin');
    }

    user.isActive = !user.isActive;
    await user.save();

    const populated = await User.findById(user._id)
      .select('-password')
      .populate('companyId', 'name code status')
      .lean();

    return success(res, 200, user.isActive ? 'Đã kích hoạt tài khoản' : 'Đã vô hiệu hóa tài khoản', populated);
  } catch (err) {
    return error(res, 500, 'Lỗi server: ' + err.message);
  }
};

module.exports = {
  getCompanies,
  getCompanyById,
  approveCompany,
  rejectCompany,
  suspendCompany,
  reactivateCompany,
  getStats,
  getUsers,
  getUserById,
  updateUserRole,
  toggleUserActive,
};

