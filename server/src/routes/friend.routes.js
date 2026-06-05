const express = require('express');
const router = express.Router();
const friendController = require('../controllers/friend.controller');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// Friend requests
router.post('/request/:userId', friendController.sendRequest);
router.put('/accept/:friendshipId', friendController.acceptRequest);
router.put('/reject/:friendshipId', friendController.rejectRequest);
router.delete('/request/:friendshipId', friendController.cancelRequest);

// Unfriend
router.delete('/:friendId', friendController.unfriend);

// Lists
router.get('/', friendController.getFriends);
router.get('/requests', friendController.getFriendRequests);
router.get('/sent', friendController.getSentRequests);
router.get('/search', friendController.searchUsers);
router.get('/count/:userId?', friendController.getFriendCount);

// Status check
router.get('/status/:userId', friendController.getFriendshipStatus);

module.exports = router;
