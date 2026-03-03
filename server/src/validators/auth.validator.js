const Joi = require('joi');

const registerSchema = Joi.object({
  email: Joi.string().email().trim().lowercase(),
  phone: Joi.string().pattern(/^[0-9]{10,11}$/).trim(),
  password: Joi.string().min(6).required(),
  fullName: Joi.string().min(2).max(50).trim().required(),
  companyCode: Joi.string().length(6).uppercase().required(),
}).or('email', 'phone').messages({
  'object.missing': 'Email hoặc số điện thoại là bắt buộc',
});

const registerCompanySchema = Joi.object({
  companyName: Joi.string().min(2).max(100).trim().required(),
  email: Joi.string().email().trim().lowercase().required(),
  phone: Joi.string().pattern(/^[0-9]{10,11}$/).trim().allow('', null),
  address: Joi.string().max(200).trim().allow('', null),
  description: Joi.string().max(500).trim().allow('', null),
  adminEmail: Joi.string().email().trim().lowercase().required(),
  adminPassword: Joi.string().min(6).required(),
  adminFullName: Joi.string().min(2).max(50).trim().required(),
});

const loginSchema = Joi.object({
  identifier: Joi.string().trim().required().messages({
    'string.empty': 'Email hoặc số điện thoại là bắt buộc',
    'any.required': 'Email hoặc số điện thoại là bắt buộc',
  }),
  password: Joi.string().required().messages({
    'string.empty': 'Mật khẩu là bắt buộc',
    'any.required': 'Mật khẩu là bắt buộc',
  }),
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

/**
 * Validation middleware factory
 * @param {Joi.Schema} schema - Joi validation schema
 */
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const details = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(422).json({
        success: false,
        message: 'Dữ liệu không hợp lệ',
        error: {
          code: 'VALIDATION_ERROR',
          details,
        },
      });
    }

    next();
  };
};

module.exports = {
  registerSchema,
  registerCompanySchema,
  loginSchema,
  refreshTokenSchema,
  validate,
};
