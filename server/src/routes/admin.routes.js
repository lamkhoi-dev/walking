const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticate } = require('../middleware/auth');
const { authorize } = require('../middleware/role');

// All admin routes require super_admin role
router.use(authenticate, authorize('super_admin'));

// Dashboard stats
router.get('/stats', adminController.getStats);

// Company management
router.get('/companies', adminController.getCompanies);
router.get('/companies/:id', adminController.getCompanyById);
router.put('/companies/:id/approve', adminController.approveCompany);
router.put('/companies/:id/reject', adminController.rejectCompany);
router.put('/companies/:id/suspend', adminController.suspendCompany);
router.put('/companies/:id/reactivate', adminController.reactivateCompany);

module.exports = router;
