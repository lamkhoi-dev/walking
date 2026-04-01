const chatService = require('../services/chat.service');
const logger = require('../utils/logger');

/**
 * Chat Socket.IO event handler
 * Handles real-time messaging, typing indicators, and read receipts
 */
const chatHandler = (io, socket) => {
  const userId = socket.userId;

  /**
   * chat:join — join a conversation room
   */
  socket.on('chat:join', async ({ conversationId }) => {
    try {
      const isParticipant = await chatService.isParticipant(conversationId, userId);
      if (!isParticipant) {
        socket.emit('chat:error', { message: 'Bạn không phải thành viên' });
        return;
      }
      socket.join(`conversation:${conversationId}`);
      logger.debug(`User ${userId} joined conversation:${conversationId}`);
    } catch (err) {
      logger.error(`chat:join error: ${err.message}`);
      socket.emit('chat:error', { message: 'Không thể tham gia hội thoại' });
    }
  });

  /**
   * chat:leave — leave a conversation room
   */
  socket.on('chat:leave', ({ conversationId }) => {
    socket.leave(`conversation:${conversationId}`);
    logger.debug(`User ${userId} left conversation:${conversationId}`);
  });

  /**
   * chat:send_message — send a message to a conversation
   */
  socket.on('chat:send_message', async ({ conversationId, type = 'text', content, imageUrl, sharedPostId }) => {
    try {
      if (!content && type !== 'image') {
        socket.emit('chat:error', { message: 'Nội dung tin nhắn không được trống' });
        return;
      }

      const isParticipant = await chatService.isParticipant(conversationId, userId);
      if (!isParticipant) {
        socket.emit('chat:error', { message: 'Bạn không phải thành viên' });
        return;
      }

      const message = await chatService.createMessage({
        conversationId,
        senderId: userId,
        type,
        content: content || '',
        imageUrl,
        sharedPostId,
      });

      // Send to all other users in the conversation room
      socket.to(`conversation:${conversationId}`).emit('chat:new_message', {
        conversationId,
        message,
      });

      // Confirm back to sender
      socket.emit('chat:message_sent', {
        conversationId,
        message,
      });
    } catch (err) {
      logger.error(`chat:send_message error: ${err.message}`);
      socket.emit('chat:error', { message: 'Không thể gửi tin nhắn' });
    }
  });

  /**
   * chat:typing — broadcast typing indicator
   */
  socket.on('chat:typing', ({ conversationId, isTyping }) => {
    socket.to(`conversation:${conversationId}`).emit('chat:user_typing', {
      conversationId,
      userId,
      fullName: socket.fullName || 'Người dùng',
      isTyping: !!isTyping,
    });
  });

  /**
   * chat:read — mark messages as read
   */
  socket.on('chat:read', async ({ conversationId }) => {
    try {
      await chatService.markAsRead(conversationId, userId);

      // Notify others that this user has read messages
      socket.to(`conversation:${conversationId}`).emit('chat:message_read', {
        conversationId,
        userId,
      });
    } catch (err) {
      logger.error(`chat:read error: ${err.message}`);
    }
  });
};

module.exports = chatHandler;
