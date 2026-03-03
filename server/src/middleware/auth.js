const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { error } = require('../utils/response');
const config = require('../config/env');

/**
 * Authenticate middleware — verify JWT token and attach user to request
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return error(res, 401, 'Token không tồn tại');
    }

    const token = authHeader.split(' ')[1];

    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, config.jwt.secret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return error(res, 401, 'Token hết hạn');
      }
      return error(res, 401, 'Token không hợp lệ');
    }

    // Find user
    const user = await User.findById(decoded.id).select('+companyId');
    if (!user) {
      return error(res, 401, 'Người dùng không tồn tại');
    }

    if (!user.isActive) {
      return error(res, 401, 'Tài khoản đã bị vô hiệu hóa');
    }

    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
};

module.exports = { authenticate };
