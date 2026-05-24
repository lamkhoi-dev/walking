const Friendship = require('../models/Friendship');
const User = require('../models/User');
const logger = require('../utils/logger');

/**
 * Send a friend request
 */
const sendRequest = async (requesterId, recipientId) => {
  // Cannot friend yourself
  if (requesterId.toString() === recipientId.toString()) {
    const err = new Error('Không thể kết bạn với chính mình');
    err.statusCode = 400;
    throw err;
  }

  // Check recipient exists
  const recipient = await User.findById(recipientId).select('blockedUsers fullName avatar role').lean();
  if (!recipient) {
    const err = new Error('Người dùng không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  // Check blocked (both directions)
  const requester = await User.findById(requesterId).select('blockedUsers').lean();
  const requesterBlocked = requester?.blockedUsers?.map((id) => id.toString()) || [];
  const recipientBlocked = recipient?.blockedUsers?.map((id) => id.toString()) || [];

  if (requesterBlocked.includes(recipientId.toString())) {
    const err = new Error('Bạn đã chặn người dùng này');
    err.statusCode = 403;
    throw err;
  }
  if (recipientBlocked.includes(requesterId.toString())) {
    const err = new Error('Không thể gửi lời mời cho người dùng này');
    err.statusCode = 403;
    throw err;
  }

  // Check existing friendship (BOTH directions)
  const existing = await Friendship.findOne({
    $or: [
      { requester: requesterId, recipient: recipientId },
      { requester: recipientId, recipient: requesterId },
    ],
  });

  if (existing) {
    if (existing.status === 'accepted') {
      const err = new Error('Đã là bạn bè');
      err.statusCode = 409;
      throw err;
    }
    if (existing.status === 'pending') {
      // If the other person already sent us a request, auto-accept
      if (existing.requester.toString() === recipientId.toString()) {
        existing.status = 'accepted';
        await existing.save();
        await existing.populate('requester', 'fullName avatar role');
        await existing.populate('recipient', 'fullName avatar role');
        return { friendship: existing, autoAccepted: true };
      }
      const err = new Error('Đã gửi lời mời trước đó');
      err.statusCode = 409;
      throw err;
    }
    // If rejected, delete old record and create new
    if (existing.status === 'rejected') {
      await Friendship.deleteOne({ _id: existing._id });
    }
  }

  const friendship = await Friendship.create({
    requester: requesterId,
    recipient: recipientId,
    status: 'pending',
  });

  await friendship.populate('requester', 'fullName avatar role');
  await friendship.populate('recipient', 'fullName avatar role');

  return { friendship, autoAccepted: false };
};

/**
 * Accept a friend request (only recipient can)
 */
const acceptRequest = async (userId, friendshipId) => {
  const friendship = await Friendship.findById(friendshipId);
  if (!friendship) {
    const err = new Error('Lời mời không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  if (friendship.recipient.toString() !== userId.toString()) {
    const err = new Error('Chỉ người nhận mới có thể chấp nhận');
    err.statusCode = 403;
    throw err;
  }

  if (friendship.status !== 'pending') {
    const err = new Error('Lời mời đã được xử lý');
    err.statusCode = 400;
    throw err;
  }

  friendship.status = 'accepted';
  await friendship.save();

  await friendship.populate('requester', 'fullName avatar role');
  await friendship.populate('recipient', 'fullName avatar role');

  return friendship;
};

/**
 * Reject a friend request (only recipient can) — deletes record to allow re-send
 */
const rejectRequest = async (userId, friendshipId) => {
  const friendship = await Friendship.findById(friendshipId);
  if (!friendship) {
    const err = new Error('Lời mời không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  if (friendship.recipient.toString() !== userId.toString()) {
    const err = new Error('Chỉ người nhận mới có thể từ chối');
    err.statusCode = 403;
    throw err;
  }

  if (friendship.status !== 'pending') {
    const err = new Error('Lời mời đã được xử lý');
    err.statusCode = 400;
    throw err;
  }

  // Delete instead of marking rejected — allows requester to re-send
  await Friendship.deleteOne({ _id: friendship._id });

  return { success: true };
};

/**
 * Cancel a sent friend request (only requester can)
 */
const cancelRequest = async (userId, friendshipId) => {
  const friendship = await Friendship.findById(friendshipId);
  if (!friendship) {
    const err = new Error('Lời mời không tồn tại');
    err.statusCode = 404;
    throw err;
  }

  if (friendship.requester.toString() !== userId.toString()) {
    const err = new Error('Chỉ người gửi mới có thể huỷ');
    err.statusCode = 403;
    throw err;
  }

  if (friendship.status !== 'pending') {
    const err = new Error('Lời mời đã được xử lý');
    err.statusCode = 400;
    throw err;
  }

  await Friendship.deleteOne({ _id: friendship._id });

  return { success: true };
};

/**
 * Unfriend — either party can unfriend
 */
const unfriend = async (userId, friendId) => {
  const result = await Friendship.findOneAndDelete({
    status: 'accepted',
    $or: [
      { requester: userId, recipient: friendId },
      { requester: friendId, recipient: userId },
    ],
  });

  if (!result) {
    const err = new Error('Không phải bạn bè');
    err.statusCode = 404;
    throw err;
  }

  return { success: true };
};

/**
 * Get friends list (paginated, searchable)
 */
const getFriends = async (userId, { page = 1, limit = 20, search } = {}) => {
  const skip = (page - 1) * limit;

  // Find all accepted friendships
  const friendships = await Friendship.find({
    status: 'accepted',
    $or: [{ requester: userId }, { recipient: userId }],
  })
    .populate('requester', 'fullName avatar role companyId')
    .populate('recipient', 'fullName avatar role companyId')
    .lean();

  // Extract friend users
  let friends = friendships.map((f) => {
    const friend =
      f.requester._id.toString() === userId.toString() ? f.recipient : f.requester;
    return {
      ...friend,
      friendshipId: f._id,
      friendsSince: f.updatedAt,
    };
  });

  // Search filter
  if (search) {
    const regex = new RegExp(search, 'i');
    friends = friends.filter((f) => regex.test(f.fullName));
  }

  const total = friends.length;
  const paginated = friends.slice(skip, skip + limit);

  return {
    friends: paginated,
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

/**
 * Get incoming friend requests (pending)
 */
const getFriendRequests = async (userId, { page = 1, limit = 20 } = {}) => {
  const skip = (page - 1) * limit;

  const [requests, total] = await Promise.all([
    Friendship.find({ recipient: userId, status: 'pending' })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('requester', 'fullName avatar role companyId')
      .lean(),
    Friendship.countDocuments({ recipient: userId, status: 'pending' }),
  ]);

  return {
    requests: requests.map((r) => ({
      friendshipId: r._id,
      user: r.requester,
      sentAt: r.createdAt,
    })),
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

/**
 * Get sent friend requests (pending)
 */
const getSentRequests = async (userId, { page = 1, limit = 20 } = {}) => {
  const skip = (page - 1) * limit;

  const [requests, total] = await Promise.all([
    Friendship.find({ requester: userId, status: 'pending' })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('recipient', 'fullName avatar role companyId')
      .lean(),
    Friendship.countDocuments({ requester: userId, status: 'pending' }),
  ]);

  return {
    requests: requests.map((r) => ({
      friendshipId: r._id,
      user: r.recipient,
      sentAt: r.createdAt,
    })),
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

/**
 * Get array of friend user IDs (for feed query)
 */
const getFriendIds = async (userId) => {
  const friendships = await Friendship.find({
    status: 'accepted',
    $or: [{ requester: userId }, { recipient: userId }],
  })
    .select('requester recipient')
    .lean();

  return friendships.map((f) =>
    f.requester.toString() === userId.toString() ? f.recipient : f.requester
  );
};

/**
 * Get friendship status between two users
 */
const getFriendshipStatus = async (userId, targetId) => {
  if (userId.toString() === targetId.toString()) {
    return { status: 'self' };
  }

  const friendship = await Friendship.findOne({
    $or: [
      { requester: userId, recipient: targetId },
      { requester: targetId, recipient: userId },
    ],
  }).lean();

  if (!friendship) {
    return { status: 'none' };
  }

  if (friendship.status === 'accepted') {
    return { status: 'friends', friendshipId: friendship._id };
  }

  if (friendship.status === 'pending') {
    if (friendship.requester.toString() === userId.toString()) {
      return { status: 'pending_sent', friendshipId: friendship._id };
    }
    return { status: 'pending_received', friendshipId: friendship._id };
  }

  return { status: 'none' };
};

/**
 * Search users to add as friends
 */
const searchUsers = async (query, userId, { page = 1, limit = 20 } = {}) => {
  const skip = (page - 1) * limit;

  // Get blocked list to exclude
  const currentUser = await User.findById(userId).select('blockedUsers').lean();
  const blockedIds = currentUser?.blockedUsers || [];

  const searchFilter = {
    _id: { $ne: userId, $nin: blockedIds },
    isActive: true,
    deletedAt: null,
    fullName: { $regex: query, $options: 'i' },
  };

  const [users, total] = await Promise.all([
    User.find(searchFilter)
      .select('fullName avatar role companyId')
      .skip(skip)
      .limit(limit)
      .lean(),
    User.countDocuments(searchFilter),
  ]);

  // Attach friendship status for each user
  const usersWithStatus = await Promise.all(
    users.map(async (user) => {
      const { status, friendshipId } = await getFriendshipStatus(userId, user._id);
      return { ...user, friendshipStatus: status, friendshipId };
    })
  );

  return {
    users: usersWithStatus,
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

/**
 * Get friend count
 */
const getFriendCount = async (userId) => {
  return Friendship.countDocuments({
    status: 'accepted',
    $or: [{ requester: userId }, { recipient: userId }],
  });
};

module.exports = {
  sendRequest,
  acceptRequest,
  rejectRequest,
  cancelRequest,
  unfriend,
  getFriends,
  getFriendRequests,
  getSentRequests,
  getFriendIds,
  getFriendshipStatus,
  searchUsers,
  getFriendCount,
};
