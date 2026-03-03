const { error } = require('../utils/response');

/**
 * Role-based authorization middleware
 * @param  {...string} roles - Allowed roles
 * @returns {Function} Express middleware
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return error(res, 401, 'Chưa xác thực');
    }

    if (!roles.includes(req.user.role)) {
      return error(res, 403, 'Bạn không có quyền truy cập');
    }

    next();
  };
};

module.exports = { authorize };
