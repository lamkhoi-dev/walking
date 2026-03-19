const Comment = require('../models/Comment');
const Post = require('../models/Post');

/**
 * Create a comment on a post
 */
const createComment = async (postId, authorId, content) => {
  const post = await Post.findOne({ _id: postId, isActive: true });
  if (!post) {
    const err = new Error('Bài viết không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  const comment = await Comment.create({
    postId,
    authorId,
    content,
  });

  // Update cached counter
  post.commentsCount += 1;
  await post.save();

  await comment.populate('authorId', 'fullName avatar');

  return comment;
};

/**
 * Get comments for a post (paginated, oldest first)
 */
const getComments = async (postId, page = 1, limit = 20) => {
  const skip = (page - 1) * limit;

  const [comments, total] = await Promise.all([
    Comment.find({ postId, isActive: true })
      .sort({ createdAt: 1 })
      .skip(skip)
      .limit(limit)
      .populate('authorId', 'fullName avatar')
      .lean(),
    Comment.countDocuments({ postId, isActive: true }),
  ]);

  return {
    comments,
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

/**
 * Delete a comment (author or admin)
 */
const deleteComment = async (commentId, userId, userRole) => {
  const comment = await Comment.findOne({ _id: commentId, isActive: true });

  if (!comment) {
    const err = new Error('Bình luận không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  const isAuthor = comment.authorId.toString() === userId.toString();
  const isAdmin = userRole === 'admin' || userRole === 'super_admin';

  if (!isAuthor && !isAdmin) {
    const err = new Error('Bạn không có quyền xóa bình luận này');
    err.statusCode = 403;
    throw err;
  }

  comment.isActive = false;
  await comment.save();

  // Update cached counter
  await Post.updateOne(
    { _id: comment.postId },
    { $inc: { commentsCount: -1 } }
  );

  return { deleted: true };
};

module.exports = {
  createComment,
  getComments,
  deleteComment,
};
