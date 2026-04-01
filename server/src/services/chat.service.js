const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const User = require('../models/User');

/**
 * Get all conversations for a user
 * Includes group convos (where user is in group.members) and direct convos
 */
const getConversations = async (userId) => {
  const conversations = await Conversation.find({
    participants: userId,
    isActive: true,
  })
    .populate({
      path: 'lastMessage',
      populate: { path: 'senderId', select: 'fullName avatar' },
    })
    .populate('participants', 'fullName avatar email phone lastOnline')
    .populate({
      path: 'groupId',
      select: 'name avatar totalMembers',
    })
    .sort({ updatedAt: -1 });

  // For each conversation, get unread count for the user
  const results = await Promise.all(
    conversations.map(async (conv) => {
      const unreadCount = await Message.countDocuments({
        conversationId: conv._id,
        senderId: { $ne: userId },
        readBy: { $nin: [userId] },
      });

      const convObj = conv.toJSON();
      convObj.unreadCount = unreadCount;
      return convObj;
    })
  );

  return results;
};

/**
 * Get or create a direct (1-on-1) conversation between two users
 */
const getOrCreateDirectConversation = async (userId, otherUserId, companyId) => {
  // Check if direct conversation already exists between these two users
  let conversation = await Conversation.findOne({
    type: 'direct',
    participants: { $all: [userId, otherUserId], $size: 2 },
  })
    .populate({
      path: 'lastMessage',
      populate: { path: 'senderId', select: 'fullName avatar' },
    })
    .populate('participants', 'fullName avatar email phone lastOnline');

  if (!conversation) {
    // Verify other user exists
    const otherUser = await User.findById(otherUserId);

    if (!otherUser) {
      const err = new Error('Người dùng không tồn tại');
      err.statusCode = 404;
      throw err;
    }

    conversation = await Conversation.create({
      type: 'direct',
      participants: [userId, otherUserId],
      companyId: companyId || undefined,
    });

    // Re-populate
    conversation = await Conversation.findById(conversation._id)
      .populate({
        path: 'lastMessage',
        populate: { path: 'senderId', select: 'fullName avatar' },
      })
      .populate('participants', 'fullName avatar email phone lastOnline');
  }

  return conversation;
};

/**
 * Get messages for a conversation with pagination
 */
const getMessages = async (conversationId, page = 1, limit = 30) => {
  const skip = (page - 1) * limit;

  const [messages, total] = await Promise.all([
    Message.find({ conversationId })
      .populate('senderId', 'fullName avatar')
      .populate({
        path: 'sharedPostId',
        populate: { path: 'authorId', select: 'fullName avatar' },
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Message.countDocuments({ conversationId }),
  ]);

  return {
    messages: messages.reverse(), // Oldest first for display
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
      hasMore: skip + messages.length < total,
    },
  };
};

/**
 * Create a new message in a conversation
 */
const createMessage = async ({ conversationId, senderId, type = 'text', content, imageUrl, sharedPostId }) => {
  const message = await Message.create({
    conversationId,
    senderId,
    type,
    content,
    imageUrl,
    sharedPostId: sharedPostId || undefined,
    readBy: [senderId], // Sender has read their own message
  });

  // Update conversation's lastMessage and updatedAt
  await Conversation.findByIdAndUpdate(conversationId, {
    lastMessage: message._id,
    updatedAt: new Date(),
  });

  // Populate sender info + shared post
  const populated = await Message.findById(message._id)
    .populate('senderId', 'fullName avatar')
    .populate({
      path: 'sharedPostId',
      populate: { path: 'authorId', select: 'fullName avatar' },
    });

  return populated;
};

/**
 * Create a system message (e.g., "User joined the group")
 */
const createSystemMessage = async (conversationId, content) => {
  const message = await Message.create({
    conversationId,
    senderId: null,
    type: 'system',
    content,
    readBy: [],
  });

  await Conversation.findByIdAndUpdate(conversationId, {
    lastMessage: message._id,
    updatedAt: new Date(),
  });

  return message;
};

/**
 * Mark messages as read for a user
 */
const markAsRead = async (conversationId, userId) => {
  const result = await Message.updateMany(
    {
      conversationId,
      senderId: { $ne: userId },
      readBy: { $nin: [userId] },
    },
    {
      $addToSet: { readBy: userId },
    }
  );

  return result.modifiedCount;
};

/**
 * Ensure user is participant of conversation
 */
const isParticipant = async (conversationId, userId) => {
  const conversation = await Conversation.findOne({
    _id: conversationId,
    participants: userId,
  });
  return !!conversation;
};

/**
 * Share a post to a group conversation by groupId
 * Finds the conversation linked to the group, then sends a shared_post message
 */
const sharePostToGroup = async (groupId, senderId, postId, content) => {
  // Find conversation for this group
  const conversation = await Conversation.findOne({
    groupId,
    isActive: true,
  });
  if (!conversation) {
    const err = new Error('Không tìm thấy hội thoại của nhóm');
    err.statusCode = 404;
    throw err;
  }

  // Verify sender is a participant
  if (!conversation.participants.some(p => p.toString() === senderId.toString())) {
    const err = new Error('Bạn không phải thành viên nhóm');
    err.statusCode = 403;
    throw err;
  }

  const message = await createMessage({
    conversationId: conversation._id,
    senderId,
    type: 'shared_post',
    content: content || 'Đã chia sẻ một bài viết',
    sharedPostId: postId,
  });

  return { message, conversationId: conversation._id };
};

module.exports = {
  getConversations,
  getOrCreateDirectConversation,
  getMessages,
  createMessage,
  createSystemMessage,
  markAsRead,
  isParticipant,
  sharePostToGroup,
};
