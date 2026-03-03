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

module.exports = {
  getCompanies,
  getCompanyById,
  approveCompany,
  rejectCompany,
  suspendCompany,
  reactivateCompany,
  getStats,
};
