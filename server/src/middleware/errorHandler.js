const logger = require('../utils/logger');
const { error } = require('../utils/response');

/**
 * Global error handler middleware
 * Must have 4 parameters for Express to recognize it as error handler
 */
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  logger.error(`${err.message}`, { 
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const details = Object.values(err.errors).map((e) => e.message);
    return error(res, 400, 'Validation Error', 'VALIDATION_ERROR', details);
  }

  // Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue).join(', ');
    return error(res, 409, `${field} đã tồn tại`, 'DUPLICATE_KEY');
  }

  // Mongoose cast error (invalid ObjectId)
  if (err.name === 'CastError') {
    return error(res, 400, `ID không hợp lệ: ${err.value}`, 'INVALID_ID');
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return error(res, 401, 'Token không hợp lệ', 'INVALID_TOKEN');
  }

  if (err.name === 'TokenExpiredError') {
    return error(res, 401, 'Token đã hết hạn', 'TOKEN_EXPIRED');
  }

  // Multer file size error
  if (err.code === 'LIMIT_FILE_SIZE') {
    return error(res, 400, 'File quá lớn. Tối đa 5MB', 'FILE_TOO_LARGE');
  }

  // Custom AppError
  if (err.statusCode) {
    return error(res, err.statusCode, err.message, err.errorCode);
  }

  // Default 500 server error
  return error(
    res, 
    500, 
    process.env.NODE_ENV === 'development' ? err.message : 'Internal Server Error',
    'INTERNAL_ERROR'
  );
};

module.exports = errorHandler;
