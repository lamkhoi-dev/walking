const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const { requireApprovedCompany } = require('../middleware/companyStatus');
const { authorize } = require('../middleware/role');
const contestController = require('../controllers/contest.controller');

// All contest routes require authentication + approved company
router.use(authenticate, requireApprovedCompany);

// POST   /                         → company_admin only → create contest
router.post('/', authorize('company_admin'), contestController.createContest);

// GET    /                         → list contests (with optional ?groupId filter)
router.get('/', contestController.getContests);

// GET    /group/:groupId/active    → get active contest for a group
router.get('/group/:groupId/active', contestController.getActiveContestByGroup);

// GET    /:id                      → get contest by ID
router.get('/:id', contestController.getContestById);

// PUT    /:id                      → company_admin only → update contest
router.put('/:id', authorize('company_admin'), contestController.updateContest);

// DELETE /:id                      → company_admin only → cancel contest
router.delete('/:id', authorize('company_admin'), contestController.cancelContest);

// GET    /:id/leaderboard          → get leaderboard
router.get('/:id/leaderboard', contestController.getLeaderboard);

module.exports = router;
