const authService = require('../services/auth.service');
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

module.exports = {
  register,
  registerCompany,
  login,
  refreshToken,
  logout,
  getMe,
};
