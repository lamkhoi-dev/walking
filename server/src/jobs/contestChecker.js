const cron = require('node-cron');
const Contest = require('../models/Contest');
const leaderboardService = require('../services/leaderboard.service');
const logger = require('../utils/logger');

/**
 * Contest Status Checker — runs every minute
 * 1. upcoming → active when startDate has passed
 * 2. active → completed when endDate has passed, then final rank recalculation
 */
const startContestChecker = () => {
  // Run every minute
  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();

      // 1. Activate upcoming contests whose startDate has passed
      const activatedResult = await Contest.updateMany(
        { status: 'upcoming', startDate: { $lte: now } },
        { $set: { status: 'active' } }
      );

      if (activatedResult.modifiedCount > 0) {
        logger.info(`Contest checker: ${activatedResult.modifiedCount} contest(s) activated`);
      }

      // 2. Complete active contests whose endDate has passed
      const completedContests = await Contest.find({
        status: 'active',
        endDate: { $lte: now },
      });

      for (const contest of completedContests) {
        contest.status = 'completed';
        await contest.save();

        // Final recalculation of ranks
        await leaderboardService.recalculateRanks(contest._id);
        logger.info(`Contest checker: contest ${contest._id} completed, ranks finalized`);
      }
    } catch (err) {
      logger.error(`Contest checker error: ${err.message}`);
    }
  });

  logger.info('✅ Contest status checker cron started (every minute)');
};

module.exports = startContestChecker;
