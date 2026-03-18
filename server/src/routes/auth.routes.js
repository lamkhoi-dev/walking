const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');
const {
  validate,
  registerSchema,
  registerCompanySchema,
  loginSchema,
  refreshTokenSchema,
} = require('../validators/auth.validator');

// Public routes (with stricter rate limiting)
router.post('/register', authLimiter, validate(registerSchema), authController.register);
router.post('/register-company', authLimiter, validate(registerCompanySchema), authController.registerCompany);
router.post('/login', authLimiter, validate(loginSchema), authController.login);
router.post('/refresh-token', authLimiter, validate(refreshTokenSchema), authController.refreshToken);

// Protected routes
router.post('/logout', authenticate, authController.logout);
router.get('/me', authenticate, authController.getMe);
router.put('/me', authenticate, authController.updateMe);
router.get('/me/stats', authenticate, authController.getMyStats);

module.exports = router;
