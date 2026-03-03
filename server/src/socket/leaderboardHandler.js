const logger = require('../utils/logger');

/**
 * Leaderboard Socket Handler
 * Manages realtime leaderboard subscriptions
 */
module.exports = (io, socket) => {
  const userId = socket.userId;

  /**
   * Subscribe to a contest leaderboard room
   * Event: 'leaderboard:subscribe'
   * Data: { contestId }
   */
  socket.on('leaderboard:subscribe', (data) => {
    try {
      const { contestId } = data || {};
      if (!contestId) return;

      const room = `contest:${contestId}`;
      socket.join(room);
      logger.debug(`User ${userId} subscribed to leaderboard: ${contestId}`);
    } catch (err) {
      logger.error('leaderboard:subscribe error:', err);
    }
  });

  /**
   * Unsubscribe from a contest leaderboard room
   * Event: 'leaderboard:unsubscribe'
   * Data: { contestId }
   */
  socket.on('leaderboard:unsubscribe', (data) => {
    try {
      const { contestId } = data || {};
      if (!contestId) return;

      const room = `contest:${contestId}`;
      socket.leave(room);
      logger.debug(`User ${userId} unsubscribed from leaderboard: ${contestId}`);
    } catch (err) {
      logger.error('leaderboard:unsubscribe error:', err);
    }
  });
};
