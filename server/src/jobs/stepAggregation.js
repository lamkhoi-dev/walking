const cron = require('node-cron');
const Contest = require('../models/Contest');
const StepRecord = require('../models/StepRecord');
const leaderboardService = require('../services/leaderboard.service');
const logger = require('../utils/logger');

/**
 * Step Aggregation — runs at 23:55 every day
 * For each active contest:
 * 1. Get today's step records for each participant
 * 2. Update contest leaderboard
 * 3. Recalculate ranks
 * This ensures accuracy beyond realtime updates
 */
const startStepAggregation = () => {
  // Run at 23:55 every day
  cron.schedule('55 23 * * *', async () => {
    try {
      const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

      // Find all active contests
      const activeContests = await Contest.find({ status: 'active' });

      if (activeContests.length === 0) {
        logger.debug('Step aggregation: no active contests');
        return;
      }

      logger.info(`Step aggregation: processing ${activeContests.length} active contest(s)`);

      for (const contest of activeContests) {
        try {
          // For each participant, get their step record for today
          for (const participantId of contest.participants) {
            const stepRecord = await StepRecord.findOne({
              userId: participantId,
              date: today,
            }).lean();

            if (stepRecord) {
              await leaderboardService.updateLeaderboard(
                participantId.toString(),
                contest._id,
                today,
                stepRecord.steps
              );
            }
          }

          // Final recalculate ranks for this contest
          await leaderboardService.recalculateRanks(contest._id);
          logger.info(`Step aggregation: contest ${contest._id} updated`);
        } catch (contestErr) {
          logger.error(`Step aggregation error for contest ${contest._id}: ${contestErr.message}`);
        }
      }

      logger.info('Step aggregation: daily sync complete');
    } catch (err) {
      logger.error(`Step aggregation error: ${err.message}`);
    }
  });

  logger.info('✅ Step aggregation cron started (daily at 23:55)');
};

module.exports = startStepAggregation;
