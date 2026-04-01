const chatService = require('../services/chat.service');
const { success, error } = require('../utils/response');

/**
 * GET /conversations — list all conversations for current user
 */
const getConversations = async (req, res, next) => {
  try {
    const conversations = await chatService.getConversations(req.user._id);
    return success(res, 200, 'Lấy danh sách hội thoại thành công', conversations);
  } catch (err) {
    next(err);
  }
};

/**
 * POST /conversations/direct — get or create a direct conversation
 * Body: { userId }
 */
const getOrCreateDirect = async (req, res, next) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return error(res, 400, 'userId là bắt buộc');
    }

    if (String(userId) === String(req.user._id)) {
      return error(res, 400, 'Không thể tạo hội thoại với chính mình');
    }

    const conversation = await chatService.getOrCreateDirectConversation(
      req.user._id,
      userId,
      req.user.companyId
    );

    return success(res, 200, 'Thành công', conversation);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /conversations/:id/messages — get messages with pagination
 * Query: ?page=1&limit=30
 */
const getMessages = async (req, res, next) => {
  try {
    const { id } = req.params;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit, 10) || 30, 50);

    // Verify user is participant
    const isParticipant = await chatService.isParticipant(id, req.user._id);
    if (!isParticipant) {
      return error(res, 403, 'Bạn không phải thành viên của hội thoại này');
    }

    const result = await chatService.getMessages(id, page, limit);
    return success(res, 200, 'Lấy tin nhắn thành công', result.messages, result.pagination);
  } catch (err) {
    next(err);
  }
};

/**
 * POST /conversations/:id/messages — send message (REST fallback)
 * Body: { type, content, imageUrl? }
 */
const createMessage = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { type = 'text', content, imageUrl } = req.body;

    if (!content) {
      return error(res, 400, 'Nội dung tin nhắn không được để trống');
    }

    // Verify user is participant
    const isParticipant = await chatService.isParticipant(id, req.user._id);
    if (!isParticipant) {
      return error(res, 403, 'Bạn không phải thành viên của hội thoại này');
    }

    const message = await chatService.createMessage({
      conversationId: id,
      senderId: req.user._id,
      type,
      content,
      imageUrl,
    });

    return success(res, 201, 'Gửi tin nhắn thành công', message);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /conversations/:id/read — mark all messages as read
 */
const markAsRead = async (req, res, next) => {
  try {
    const { id } = req.params;

    const isParticipant = await chatService.isParticipant(id, req.user._id);
    if (!isParticipant) {
      return error(res, 403, 'Bạn không phải thành viên của hội thoại này');
    }

    const count = await chatService.markAsRead(id, req.user._id);
    return success(res, 200, 'Đã đánh dấu đã đọc', { markedCount: count });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /conversations/:id/upload — upload image message
 * Multipart form: image file
 */
const uploadImage = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!req.file) {
      return error(res, 400, 'Chưa chọn file ảnh');
    }

    // Verify user is participant
    const isParticipant = await chatService.isParticipant(id, req.user._id);
    if (!isParticipant) {
      return error(res, 403, 'Bạn không phải thành viên của hội thoại này');
    }

    const message = await chatService.createMessage({
      conversationId: id,
      senderId: req.user._id,
      type: 'image',
      content: '[Hình ảnh]',
      imageUrl: req.file.path,
    });

    return success(res, 201, 'Gửi ảnh thành công', message);
  } catch (err) {
    next(err);
  }
};

/**
 * POST /share-post — share a post to group chat(s)
 * Body: { postId, groupIds: [...], content? }
 */
const sharePostToGroups = async (req, res, next) => {
  try {
    const { postId, groupIds, content } = req.body;

    if (!postId) {
      return error(res, 400, 'postId là bắt buộc');
    }
    if (!groupIds || !Array.isArray(groupIds) || groupIds.length === 0) {
      return error(res, 400, 'groupIds là bắt buộc');
    }

    const results = [];
    const errors = [];

    for (const groupId of groupIds) {
      try {
        const result = await chatService.sharePostToGroup(
          groupId,
          req.user._id,
          postId,
          content,
        );
        results.push({
          groupId,
          conversationId: result.conversationId,
          messageId: result.message._id,
        });
      } catch (err) {
        errors.push({ groupId, error: err.message });
      }
    }

    return success(res, 201, `Đã chia sẻ đến ${results.length} nhóm`, {
      shared: results,
      errors,
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getConversations,
  getOrCreateDirect,
  getMessages,
  createMessage,
  markAsRead,
  uploadImage,
  sharePostToGroups,
};
