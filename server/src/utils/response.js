/**
 * Standard success response
 * @param {import('express').Response} res
 * @param {number} statusCode
 * @param {string} message
 * @param {any} data
 * @param {object} pagination
 */
const success = (res, statusCode = 200, message = 'Success', data = null, pagination = null) => {
  const response = {
    success: true,
    message,
  };

  if (data !== null) {
    response.data = data;
  }

  if (pagination) {
    response.pagination = pagination;
  }

  return res.status(statusCode).json(response);
};

/**
 * Standard error response
 * @param {import('express').Response} res
 * @param {number} statusCode
 * @param {string} message
 * @param {string} errorCode
 * @param {any} details
 */
const error = (res, statusCode = 500, message = 'Internal Server Error', errorCode = null, details = null) => {
  const response = {
    success: false,
    message,
  };

  if (errorCode || details) {
    response.error = {};
    if (errorCode) response.error.code = errorCode;
    if (details) response.error.details = details;
  }

  return res.status(statusCode).json(response);
};

module.exports = { success, error };
