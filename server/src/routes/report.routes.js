const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');
const { authenticate } = require('../middleware/auth');

// Protected routes
router.post('/', authenticate, reportController.createReport);

module.exports = router;
