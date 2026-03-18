const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const settingsController = require('../controllers/settings.controller');

// All settings routes require authentication
router.use(authenticate);

// GET  / → get user settings
router.get('/', settingsController.getSettings);

// PUT  / → update user settings
router.put('/', settingsController.updateSettings);

module.exports = router;
