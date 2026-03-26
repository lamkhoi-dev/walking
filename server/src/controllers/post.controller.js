const postService = require('../services/post.service');
const commentService = require('../services/comment.service');
const { success, error } = require('../utils/response');

/**
 * POST /posts — create a new post
 * Body: { content, visibility, visibleToGroups?, media? }
 */
const createPost = async (req, res, next) => {
  try {
    const { content, visibility, visibleToGroups, type, sharedPostId, sharedContestId, achievementRank, achievementSteps } = req.body;

    // Allow content-empty for shared posts/contests
    const isShared = type === 'shared_post' || type === 'shared_contest';
    if (!content && !isShared && (!req.files || req.files.length === 0)) {
      return error(res, 400, 'Nội dung hoặc ảnh không được để trống');
    }

    // Build media array from uploaded files
    let media = [];
    if (req.files && req.files.length > 0) {
      media = req.files.map((file) => ({
        url: file.path,
        publicId: file.filename,
        width: 0,
        height: 0,
      }));
    }

    const post = await postService.createPost(req.user._id, {
      content,
      visibility,
      visibleToGroups: (() => {
        if (!visibleToGroups) return [];
        if (Array.isArray(visibleToGroups)) return visibleToGroups;
        if (typeof visibleToGroups === 'string') {
          // Try JSON parse first, fallback to comma-separated
          try { return JSON.parse(visibleToGroups); } catch { return visibleToGroups.split(',').filter(Boolean); }
        }
        return [];
      })(),
      media,
      type,
      sharedPostId: sharedPostId || null,
      sharedContestId: sharedContestId || null,
      achievementRank: achievementRank ? parseInt(achievementRank) : null,
      achievementSteps: achievementSteps ? parseInt(achievementSteps) : null,
    });

    return success(res, 201, 'Tạo bài viết thành công', post);
  } catch (err) {
    if (err.statusCode) return error(res, err.statusCode, err.message);
    next(err);
  }
};

/**
 * GET /posts/feed — get feed with visibility filtering
 * Query: ?filter=all|public|group:ID&page=1&limit=20
 */
const getFeed = async (req, res, next) => {
  try {
    const filter = req.query.filter || 'all';
    const page = parseInt(req.query.page, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);

    const result = await postService.getFeed(req.user._id, {
      filter,
      page,
      limit,
    });

    return success(res, 200, 'Lấy feed thành công', result.posts, result.pagination);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /posts/:id — get single post
 */
const getPostById = async (req, res, next) => {
  try {
    const post = await postService.getPostById(req.params.id, req.user._id);
    return success(res, 200, 'Lấy bài viết thành công', post);
  } catch (err) {
    if (err.statusCode) return error(res, err.statusCode, err.message);
    next(err);
  }
};

/**
 * PUT /posts/:id — update post (author only)
 */
const updatePost = async (req, res, next) => {
  try {
    const post = await postService.updatePost(
      req.params.id,
      req.user._id,
      req.body
    );
    return success(res, 200, 'Cập nhật bài viết thành công', post);
  } catch (err) {
    if (err.statusCode) return error(res, err.statusCode, err.message);
    next(err);
  }
};

/**
 * DELETE /posts/:id — soft delete post
 */
const deletePost = async (req, res, next) => {
  try {
    const result = await postService.deletePost(
      req.params.id,
      req.user._id,
      req.user.role
    );
    return success(res, 200, 'Xóa bài viết thành công', result);
  } catch (err) {
    if (err.statusCode) return error(res, err.statusCode, err.message);
    next(err);
  }
};

/**
 * POST /posts/:id/like — toggle like
 */
const toggleLike = async (req, res, next) => {
  try {
    const result = await postService.toggleLike(req.user._id, req.params.id);
    return success(res, 200, result.liked ? 'Đã thích' : 'Đã bỏ thích', result);
  } catch (err) {
    if (err.statusCode) return error(res, err.statusCode, err.message);
    next(err);
  }
};

/**
 * GET /posts/:id/likes — list likes
 */
const getLikes = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const result = await postService.getLikes(req.params.id, page);
    return success(res, 200, 'Lấy danh sách thích thành công', result.likes, result.pagination);
  } catch (err) {
    next(err);
  }
};

/**
 * POST /posts/:id/comments — create comment
 */
const createComment = async (req, res, next) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) {
      return error(res, 400, 'Nội dung bình luận không được để trống');
    }

    const comment = await commentService.createComment(
      req.params.id,
      req.user._id,
      content.trim()
    );
    return success(res, 201, 'Bình luận thành công', comment);
  } catch (err) {
    if (err.statusCode) return error(res, err.statusCode, err.message);
    next(err);
  }
};

/**
 * GET /posts/:id/comments — list comments (paginated)
 */
const getComments = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
    const result = await commentService.getComments(req.params.id, page, limit);
    return success(res, 200, 'Lấy bình luận thành công', result.comments, result.pagination);
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /posts/comments/:id — delete comment
 */
const deleteComment = async (req, res, next) => {
  try {
    const result = await commentService.deleteComment(
      req.params.id,
      req.user._id,
      req.user.role
    );
    return success(res, 200, 'Xóa bình luận thành công', result);
  } catch (err) {
    if (err.statusCode) return error(res, err.statusCode, err.message);
    next(err);
  }
};

module.exports = {
  createPost,
  getFeed,
  getPostById,
  updatePost,
  deletePost,
  toggleLike,
  getLikes,
  createComment,
  getComments,
  deleteComment,
};
