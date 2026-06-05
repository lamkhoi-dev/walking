const Post = require('../models/Post');
const Like = require('../models/Like');
const Group = require('../models/Group');
const User = require('../models/User');
const friendService = require('./friend.service');
const logger = require('../utils/logger');

/**
 * Create a new post
 * Handles visibility normalization: 'all_groups' → populates visibleToGroups with author's groups
 */
const createPost = async (authorId, { content, visibility, visibleToGroups, media, type, sharedPostId, sharedContestId, achievementRank, achievementSteps, mediaLayout }) => {
  const author = await User.findById(authorId).select('companyId role');
  if (!author) {
    const err = new Error('Người dùng không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  // Normalize visibility
  let finalVisibility = visibility || 'public';
  let finalGroups = [];

  if (visibility === 'all_groups') {
    // Find all groups where the author is a member
    const groups = await Group.find({
      members: authorId,
      isActive: true,
    }).select('_id');
    finalGroups = groups.map((g) => g._id);
    finalVisibility = 'groups';
  } else if (visibility === 'groups' && Array.isArray(visibleToGroups)) {
    // Verify author is member of all selected groups
    const validGroups = await Group.find({
      _id: { $in: visibleToGroups },
      members: authorId,
      isActive: true,
    }).select('_id');
    finalGroups = validGroups.map((g) => g._id);
    finalVisibility = 'groups';
  }

  // Determine post type
  let postType = type || 'text';
  if (!type && media && media.length > 0) {
    const hasVideo = media.some((m) => m.type === 'video');
    postType = hasVideo ? 'video' : 'image';
  }

  // Auto-set isOfficial for company_admin
  const isOfficial = author.role === 'company_admin';

  const post = await Post.create({
    authorId,
    companyId: author.companyId || null,
    visibility: finalVisibility,
    visibleToGroups: finalGroups,
    type: postType,
    content: content || '',
    media: media || [],
    mediaLayout: mediaLayout || null,
    isOfficial,
    sharedPostId: sharedPostId || undefined,
    sharedContestId: sharedContestId || undefined,
    achievementRank: achievementRank || undefined,
    achievementSteps: achievementSteps || undefined,
  });

  // Populate author + shared content before returning
  await post.populate('authorId', 'fullName avatar');
  if (sharedContestId) {
    await post.populate('sharedContestId', 'name description status startDate endDate');
  }
  if (sharedPostId) {
    await post.populate({ path: 'sharedPostId', populate: { path: 'authorId', select: 'fullName avatar' } });
  }

  return post;
};

/**
 * Get feed with visibility-aware filtering
 * Public posts = system-wide (cross-company)
 * Group posts = only visible to group members
 */
const getFeed = async (userId, { filter, page = 1, limit = 20 }) => {
  const skip = (page - 1) * limit;

  // Parallelize prerequisite queries for performance
  const [userGroups, currentUser, friendIds] = await Promise.all([
    Group.find({ members: userId, isActive: true }).select('_id').lean(),
    User.findById(userId).select('blockedUsers').lean(),
    friendService.getFriendIds(userId),
  ]);

  const userGroupIds = userGroups.map((g) => g._id);
  const blockedUserIds = currentUser?.blockedUsers || [];

  let query = { isActive: true };

  // Exclude posts from blocked users
  if (blockedUserIds.length > 0) {
    query.authorId = { $nin: blockedUserIds };
  }

  if (filter === 'mine') {
    // Only user's own posts (for profile page)
    query.authorId = userId;
  } else if (filter === 'public') {
    // Only public posts (system-wide)
    query.visibility = 'public';
  } else if (filter === 'friends') {
    // Posts from friends (public + friends-only)
    if (friendIds.length > 0) {
      query.authorId = { ...query.authorId, $in: friendIds };
    } else {
      // No friends → return empty
      query._id = null;
    }
  } else if (filter && filter.startsWith('group:')) {
    // Posts visible to a specific group
    const groupId = filter.replace('group:', '');
    query.visibleToGroups = groupId;
  } else {
    // Default "all" feed: public + user's groups + friends' friends-only posts
    query.$or = [
      { visibility: 'public' },
      { visibleToGroups: { $in: userGroupIds } },
      ...(friendIds.length > 0
        ? [{ visibility: 'friends', authorId: { $in: friendIds } }]
        : []),
    ];
  }

  const [posts, total] = await Promise.all([
    Post.find(query)
      .sort({ isPinned: -1, pinnedAt: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('authorId', 'fullName avatar')
      .populate('visibleToGroups', 'name')
      .populate({
        path: 'sharedPostId',
        populate: { path: 'authorId', select: 'fullName avatar' },
      })
      .populate({
        path: 'sharedContestId',
        select: 'name description status startDate endDate',
      })
      .lean(),
    Post.countDocuments(query),
  ]);

  // Check if current user liked each post
  const postIds = posts.map((p) => p._id);
  const userLikes = await Like.find({
    userId,
    postId: { $in: postIds },
  }).select('postId');
  const likedPostIds = new Set(userLikes.map((l) => l.postId.toString()));

  const postsWithLikeStatus = posts.map((post) => ({
    ...post,
    isLiked: likedPostIds.has(post._id.toString()),
  }));

  return {
    posts: postsWithLikeStatus,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
    },
  };
};

/**
 * Get a single post by ID
 */
const getPostById = async (postId, userId) => {
  const post = await Post.findOne({ _id: postId, isActive: true })
    .populate('authorId', 'fullName avatar')
    .populate('visibleToGroups', 'name')
    .populate({
      path: 'sharedPostId',
      populate: { path: 'authorId', select: 'fullName avatar' },
    })
    .populate({
      path: 'sharedContestId',
      select: 'name description status startDate endDate',
    })
    .lean();

  if (!post) {
    const err = new Error('Bài viết không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  // Check visibility access
  if (post.visibility === 'groups') {
    const isMember = await Group.exists({
      _id: { $in: post.visibleToGroups.map((g) => g._id || g) },
      members: userId,
    });
    if (!isMember) {
      const err = new Error('Bạn không có quyền xem bài viết này');
      err.statusCode = 403;
      throw err;
    }
  }

  // Check if liked
  const like = await Like.exists({ userId, postId });
  post.isLiked = !!like;

  return post;
};

/**
 * Update a post (author only)
 */
const updatePost = async (postId, authorId, updates) => {
  const post = await Post.findOne({ _id: postId, isActive: true });

  if (!post) {
    const err = new Error('Bài viết không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  if (post.authorId.toString() !== authorId.toString()) {
    const err = new Error('Bạn không có quyền chỉnh sửa bài viết này');
    err.statusCode = 403;
    throw err;
  }

  const allowedUpdates = ['content'];
  const filteredUpdates = {};
  for (const key of allowedUpdates) {
    if (updates[key] !== undefined) {
      filteredUpdates[key] = updates[key];
    }
  }

  Object.assign(post, filteredUpdates);
  if (filteredUpdates.content !== undefined) {
    post.editedAt = new Date();
  }
  await post.save();
  await post.populate('authorId', 'fullName avatar');

  return post;
};

/**
 * Soft delete a post (author or admin)
 */
const deletePost = async (postId, userId, userRole) => {
  const post = await Post.findOne({ _id: postId, isActive: true });

  if (!post) {
    const err = new Error('Bài viết không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  const isAuthor = post.authorId.toString() === userId.toString();
  const isAdmin = userRole === 'company_admin' || userRole === 'super_admin';

  if (!isAuthor && !isAdmin) {
    const err = new Error('Bạn không có quyền xóa bài viết này');
    err.statusCode = 403;
    throw err;
  }

  post.isActive = false;
  await post.save();

  return { deleted: true };
};

/**
 * Toggle like on a post
 */
const toggleLike = async (userId, postId) => {
  const post = await Post.findOne({ _id: postId, isActive: true });
  if (!post) {
    const err = new Error('Bài viết không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  const existingLike = await Like.findOne({ userId, postId });

  if (existingLike) {
    await Like.deleteOne({ _id: existingLike._id });
    post.likesCount = Math.max(0, post.likesCount - 1);
    await post.save();
    return { liked: false, likesCount: post.likesCount };
  }

  await Like.create({ userId, postId });
  post.likesCount += 1;
  await post.save();
  return { liked: true, likesCount: post.likesCount };
};

/**
 * Get likes for a post (paginated)
 */
const getLikes = async (postId, page = 1, limit = 20) => {
  const skip = (page - 1) * limit;

  const [likes, total] = await Promise.all([
    Like.find({ postId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('userId', 'fullName avatar')
      .lean(),
    Like.countDocuments({ postId }),
  ]);

  return {
    likes,
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

/**
 * Toggle pin on a post (company_admin only, max 3 per company)
 */
const togglePin = async (postId, userId) => {
  const user = await User.findById(userId).select('role companyId');
  if (!user || user.role !== 'company_admin') {
    const err = new Error('Chỉ admin công ty mới có thể ghim bài viết');
    err.statusCode = 403;
    throw err;
  }

  const post = await Post.findOne({ _id: postId, isActive: true });
  if (!post) {
    const err = new Error('Bài viết không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  // Must be same company
  if (!post.companyId || post.companyId.toString() !== user.companyId?.toString()) {
    const err = new Error('Bạn chỉ có thể ghim bài trong công ty của mình');
    err.statusCode = 403;
    throw err;
  }

  if (post.isPinned) {
    // Unpin
    post.isPinned = false;
    post.pinnedAt = null;
    await post.save();
  } else {
    // Check pin limit (max 3)
    const pinnedCount = await Post.countDocuments({
      companyId: post.companyId,
      isPinned: true,
      isActive: true,
    });

    if (pinnedCount >= 3) {
      // Auto-unpin the oldest
      const oldest = await Post.findOne({
        companyId: post.companyId,
        isPinned: true,
        isActive: true,
      }).sort({ pinnedAt: 1 });
      if (oldest) {
        oldest.isPinned = false;
        oldest.pinnedAt = null;
        await oldest.save();
      }
    }

    post.isPinned = true;
    post.pinnedAt = new Date();
    await post.save();
  }

  await post.populate('authorId', 'fullName avatar');
  return post;
};

/**
 * Get posts by a specific user (for profile page)
 * Visibility-filtered based on viewer's relationship
 */
const getUserPosts = async (authorId, viewerId, { page = 1, limit = 20 } = {}) => {
  const skip = (page - 1) * limit;
  const isOwnProfile = authorId.toString() === viewerId.toString();

  let visibilityFilter;
  if (isOwnProfile) {
    // Own profile: see all own posts
    visibilityFilter = {};
  } else {
    // Check friendship
    const { status } = await friendService.getFriendshipStatus(viewerId, authorId);
    if (status === 'friends') {
      // Friend: see public + friends posts
      visibilityFilter = { visibility: { $in: ['public', 'friends'] } };
    } else {
      // Stranger: only public posts
      visibilityFilter = { visibility: 'public' };
    }
  }

  const query = { authorId, isActive: true, ...visibilityFilter };

  const [posts, total] = await Promise.all([
    Post.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('authorId', 'fullName avatar')
      .populate('visibleToGroups', 'name')
      .lean(),
    Post.countDocuments(query),
  ]);

  // Check likes
  const postIds = posts.map((p) => p._id);
  const userLikes = await Like.find({ userId: viewerId, postId: { $in: postIds } }).select('postId');
  const likedPostIds = new Set(userLikes.map((l) => l.postId.toString()));

  return {
    posts: posts.map((post) => ({ ...post, isLiked: likedPostIds.has(post._id.toString()) })),
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

module.exports = {
  createPost,
  getFeed,
  getPostById,
  updatePost,
  deletePost,
  toggleLike,
  getLikes,
  togglePin,
  getUserPosts,
};
