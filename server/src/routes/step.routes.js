const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const { requireApprovedCompany } = require('../middleware/companyStatus');
const stepController = require('../controllers/step.controller');

// All step routes require authentication + approved company
router.use(authenticate, requireApprovedCompany);

// POST /sync    → sync steps from client
router.post('/sync', stepController.syncSteps);

// GET  /today   → get today's step data
router.get('/today', stepController.getToday);

// GET  /history → get step history (query: from, to)
router.get('/history', stepController.getHistory);

// GET  /stats   → get step statistics
router.get('/stats', stepController.getStats);

module.exports = router;
