const stepService = require('../services/step.service');
const leaderboardService = require('../services/leaderboard.service');
const logger = require('../utils/logger');

/**
 * Step Socket.IO event handler
 * Handles real-time step sync via socket
 */
const stepHandler = (io, socket) => {
  const userId = socket.userId;
  const companyId = socket.companyId;

  /**
   * steps:sync — sync step data via socket (preferred over REST for speed)
   */
  socket.on('steps:sync', async ({ date, steps, hourlySteps }) => {
    try {
      if (!date || typeof steps !== 'number' || steps < 0) {
        socket.emit('steps:error', { message: 'Dữ liệu bước không hợp lệ' });
        return;
      }

      const record = await stepService.syncSteps(userId, companyId, {
        date,
        steps,
        hourlySteps,
      });

      // Confirm back to sender
      socket.emit('steps:synced', {
        success: true,
        todaySteps: record.steps,
        distance: record.distance,
        calories: record.calories,
        date: record.date,
      });

      logger.debug(`Steps synced via socket: user=${userId}, steps=${steps}`);

      // Update contest leaderboards if user is in active contests
      try {
        const activeContests = await leaderboardService.getActiveContestsForUser(userId);
        for (const contest of activeContests) {
          const leaderboard = await leaderboardService.updateLeaderboard(
            userId,
            contest._id,
            date,
            steps
          );
          if (leaderboard) {
            // Broadcast updated leaderboard to all subscribers
            io.to(`contest:${contest._id}`).emit('leaderboard:update', {
              contestId: contest._id.toString(),
              leaderboard,
            });
          }
        }
      } catch (leaderboardErr) {
        logger.error(`Leaderboard update error: ${leaderboardErr.message}`);
        // Don't fail the sync if leaderboard update fails
      }
    } catch (err) {
      logger.error(`steps:sync error: ${err.message}`);
      socket.emit('steps:error', { message: 'Không thể đồng bộ bước' });
    }
  });

  /**
   * steps:get_today — quick fetch of today's data via socket
   */
  socket.on('steps:get_today', async () => {
    try {
      const data = await stepService.getToday(userId);
      socket.emit('steps:today', data);
    } catch (err) {
      logger.error(`steps:get_today error: ${err.message}`);
    }
  });
};

module.exports = stepHandler;
