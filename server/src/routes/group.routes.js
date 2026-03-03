const express = require('express');
const router = express.Router();
const groupController = require('../controllers/group.controller');
const { authenticate } = require('../middleware/auth');
const { authorize } = require('../middleware/role');
const { requireApprovedCompany } = require('../middleware/companyStatus');

// All group routes require auth + approved company
router.use(authenticate, requireApprovedCompany);

// Group CRUD
router.post('/', authorize('company_admin'), groupController.createGroup);
router.get('/', groupController.getGroups);
router.get('/search', groupController.searchGroups);
router.get('/:id', groupController.getGroupById);
router.put('/:id', authorize('company_admin'), groupController.updateGroup);
router.delete('/:id', authorize('company_admin'), groupController.deleteGroup);

// Member management
router.post('/:id/members', authorize('company_admin'), groupController.addMembers);
router.delete('/:id/members/:userId', authorize('company_admin'), groupController.removeMember);

// Join by QR
router.post('/join/:groupId', groupController.joinByQR);

module.exports = router;
