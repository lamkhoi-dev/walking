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

    // User without company → allow through (free user)
    if (!req.user.companyId) {
      req.company = null;
      return next();
    }

    const company = await Company.findById(req.user.companyId);
    if (!company) {
      // Company reference invalid → treat as free user
      req.company = null;
      return next();
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
