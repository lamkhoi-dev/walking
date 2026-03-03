const mongoose = require('mongoose');

/**
 * ContestLeaderboard — tracks each participant's steps in a contest
 */
const contestLeaderboardSchema = new mongoose.Schema(
  {
    contestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Contest',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    totalSteps: {
      type: Number,
      default: 0,
      min: 0,
    },
    // Daily steps breakdown: { "2024-01-15": 5000, "2024-01-16": 8000 }
    dailySteps: {
      type: Map,
      of: Number,
      default: {},
    },
    rank: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index: one record per user per contest
contestLeaderboardSchema.index({ contestId: 1, userId: 1 }, { unique: true });

// For leaderboard queries
contestLeaderboardSchema.index({ contestId: 1, totalSteps: -1 });

module.exports = mongoose.model('ContestLeaderboard', contestLeaderboardSchema);
