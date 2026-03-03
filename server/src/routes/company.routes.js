const express = require('express');
const router = express.Router();
const companyController = require('../controllers/company.controller');
const { authenticate } = require('../middleware/auth');
const { requireApprovedCompany } = require('../middleware/companyStatus');

// Get company status (no requireApprovedCompany — needed for pending/rejected flows)
router.get('/status', authenticate, companyController.getCompanyStatus);

// Get company members (requires approved company)
router.get('/members', authenticate, requireApprovedCompany, companyController.getCompanyMembers);

module.exports = router;
