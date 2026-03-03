const Company = require('../models/Company');
const { error } = require('../utils/response');

/**
 * Middleware to check if user's company is approved.
 * Skips check for super_admin role.
 */
const requireApprovedCompany = async (req, res, next) => {
  try {
    // Super admin bypasses company check
    if (req.user.role === 'super_admin') {
      return next();
    }

    // User must have a companyId
    if (!req.user.companyId) {
      return error(res, 403, 'Không tìm thấy thông tin công ty');
    }

    const company = await Company.findById(req.user.companyId);
    if (!company) {
      return error(res, 403, 'Công ty không tồn tại');
    }

    switch (company.status) {
      case 'approved':
        req.company = company;
        return next();
      case 'pending':
        return error(res, 403, 'Công ty đang chờ phê duyệt');
      case 'rejected':
        return error(res, 403, 'Công ty đã bị từ chối');
      case 'suspended':
        return error(res, 403, 'Công ty đã bị tạm ngưng');
      default:
        return error(res, 403, 'Trạng thái công ty không hợp lệ');
    }
  } catch (err) {
    next(err);
  }
};

module.exports = { requireApprovedCompany };
