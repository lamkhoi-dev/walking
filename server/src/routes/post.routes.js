const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const { requireApprovedCompany } = require('../middleware/companyStatus');
const postController = require('../controllers/post.controller');
const { postUpload } = require('../middleware/upload');

// All post routes require authentication
router.use(authenticate, requireApprovedCompany);

// === FEED ===
// GET    /posts/feed                → get feed (visibility-filtered)
router.get('/feed', postController.getFeed);

// === POSTS CRUD ===
// POST   /posts                     → create post (with optional images)
router.post('/', postUpload.array('images', 4), postController.createPost);

// GET    /posts/:id                 → get single post
router.get('/:id', postController.getPostById);

// PUT    /posts/:id                 → update post (author only)
router.put('/:id', postController.updatePost);

// DELETE /posts/:id                 → soft delete post
router.delete('/:id', postController.deletePost);

// === LIKES ===
// POST   /posts/:id/like            → toggle like
router.post('/:id/like', postController.toggleLike);

// GET    /posts/:id/likes           → list likes
router.get('/:id/likes', postController.getLikes);

// === COMMENTS ===
// POST   /posts/:id/comments        → create comment
router.post('/:id/comments', postController.createComment);

// GET    /posts/:id/comments        → list comments (paginated)
router.get('/:id/comments', postController.getComments);

// DELETE /posts/comments/:commentId → delete comment
router.delete('/comments/:id', postController.deleteComment);

module.exports = router;
