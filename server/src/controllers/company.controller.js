const Company = require('../models/Company');
const User = require('../models/User');
const { success, error } = require('../utils/response');
const escapeRegex = require('../utils/escapeRegex');

/**
 * Get current user's company status
 * GET /api/v1/companies/status
 */
const getCompanyStatus = async (req, res, next) => {
  try {
    if (!req.user.companyId) {
      return error(res, 404, 'Không tìm thấy thông tin công ty');
    }

    const company = await Company.findById(req.user.companyId).select(
      '_id name status code updatedAt'
    );

    if (!company) {
      return error(res, 404, 'Công ty không tồn tại');
    }

    return success(res, 200, 'Thành công', {
      companyId: company._id,
      name: company.name,
      status: company.status,
      code: company.code,
      updatedAt: company.updatedAt,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Get members of the current user's company
 * GET /api/v1/companies/members
 */
const getCompanyMembers = async (req, res, next) => {
  try {
    const { page = 1, limit = 50, search } = req.query;
    const pageNum = Math.max(1, parseInt(page, 10));
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const skip = (pageNum - 1) * limitNum;

    const filter = {
      companyId: req.user.companyId,
      role: { $ne: 'super_admin' },
      isActive: true,
    };

    if (search) {
      filter.fullName = { $regex: escapeRegex(search), $options: 'i' };
    }

    const [members, total] = await Promise.all([
      User.find(filter)
        .select('_id fullName email phone avatar role')
        .sort({ fullName: 1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      User.countDocuments(filter),
    ]);

    return success(res, 200, 'Lấy danh sách thành viên thành công', members, {
      page: pageNum,
      limit: limitNum,
      total,
      totalPages: Math.ceil(total / limitNum),
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getCompanyStatus,
  getCompanyMembers,
};
