const ContestLeaderboard = require('../models/ContestLeaderboard');
const Contest = require('../models/Contest');
const logger = require('../utils/logger');

class LeaderboardService {
  /**
   * Update leaderboard for a user in a contest
   * @param {string} userId
   * @param {string} contestId
   * @param {string} date - YYYY-MM-DD
   * @param {number} steps - total steps for that date
   */
  async updateLeaderboard(userId, contestId, date, steps) {
    const entry = await ContestLeaderboard.findOne({ contestId, userId });

    if (!entry) {
      logger.warn(`Leaderboard entry not found: contest=${contestId}, user=${userId}`);
      return null;
    }

    // Update daily steps for the date
    entry.dailySteps.set(date, steps);

    // Recalculate total steps from all daily entries
    let totalSteps = 0;
    for (const [, daySteps] of entry.dailySteps) {
      totalSteps += daySteps;
    }
    entry.totalSteps = totalSteps;

    await entry.save();

    // Recalculate ranks for all participants in this contest
    const updatedLeaderboard = await this.recalculateRanks(contestId);

    return updatedLeaderboard;
  }

  /**
   * Recalculate ranks for all participants in a contest
   */
  async recalculateRanks(contestId) {
    const entries = await ContestLeaderboard.find({ contestId })
      .sort({ totalSteps: -1 })
      .populate('userId', 'fullName avatar');

    let currentRank = 1;
    for (let i = 0; i < entries.length; i++) {
      if (i > 0 && entries[i].totalSteps < entries[i - 1].totalSteps) {
        currentRank = i + 1;
      }
      entries[i].rank = currentRank;
      await entries[i].save();
    }

    return entries.map((e) => e.toJSON());
  }

  /**
   * Get active contests for a user
   * Returns contests where user is a participant and status is 'active'
   */
  async getActiveContestsForUser(userId) {
    const contests = await Contest.find({
      participants: userId,
      status: 'active',
    }).lean();

    return contests;
  }
}

module.exports = new LeaderboardService();
