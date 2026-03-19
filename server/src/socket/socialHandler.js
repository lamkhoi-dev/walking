const logger = require('../utils/logger');

/**
 * Social feed socket handler
 * Broadcasts new post notifications to relevant rooms
 */
module.exports = (io, socket) => {
  /**
   * When a new post is created, the server or controller can call:
   *   io.to(`company:${companyId}`).emit('social:new_post', { postId, authorName })
   *   io.to(`group:${groupId}`).emit('social:new_post', { postId, authorName })
   *
   * The client listens for 'social:new_post' to show the "Có bài viết mới" banner.
   *
   * For public posts:
   *   io.emit('social:new_post', { postId, authorName, visibility: 'public' })
   */

  // Join company room on connect (for receiving company-wide notifications)
  if (socket.user && socket.user.companyId) {
    socket.join(`company:${socket.user.companyId}`);
    logger.info(`Socket ${socket.id} joined company room: company:${socket.user.companyId}`);
  }

  // Join group rooms for the user's groups
  socket.on('social:join_groups', (groupIds) => {
    if (Array.isArray(groupIds)) {
      groupIds.forEach((groupId) => {
        socket.join(`group:${groupId}`);
      });
      logger.info(`Socket ${socket.id} joined ${groupIds.length} group rooms`);
    }
  });

  // Notify about a new post (called from controller after post creation)
  socket.on('social:notify_new_post', (data) => {
    if (!data || !data.postId) return;

    const { postId, authorName, visibility, visibleToGroups, companyId } = data;
    const payload = { postId, authorName, createdAt: new Date().toISOString() };

    if (visibility === 'public') {
      // Broadcast to ALL connected clients (system-wide)
      socket.broadcast.emit('social:new_post', { ...payload, visibility: 'public' });
    } else if (visibility === 'groups' && Array.isArray(visibleToGroups)) {
      // Broadcast to specific group rooms
      visibleToGroups.forEach((groupId) => {
        socket.to(`group:${groupId}`).emit('social:new_post', { ...payload, visibility: 'groups' });
      });
    }
  });
};
