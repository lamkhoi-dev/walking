const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const { requireApprovedCompany } = require('../middleware/companyStatus');
const chatController = require('../controllers/chat.controller');
const { chatUpload } = require('../middleware/upload');

// All chat routes require authentication + approved company
router.use(authenticate, requireApprovedCompany);

// GET    /conversations              → list conversations
router.get('/conversations', chatController.getConversations);

// POST   /conversations/direct       → get or create direct conversation
router.post('/conversations/direct', chatController.getOrCreateDirect);

// GET    /conversations/:id/messages → get messages (paginated)
router.get('/conversations/:id/messages', chatController.getMessages);

// POST   /conversations/:id/messages → send message (REST fallback)
router.post('/conversations/:id/messages', chatController.createMessage);

// POST   /conversations/:id/upload   → upload image message
router.post('/conversations/:id/upload', chatUpload.single('image'), chatController.uploadImage);

// PUT    /conversations/:id/read     → mark as read
router.put('/conversations/:id/read', chatController.markAsRead);

// POST   /share-post                 → share a post to group chat(s)
router.post('/share-post', chatController.sharePostToGroups);

module.exports = router;
