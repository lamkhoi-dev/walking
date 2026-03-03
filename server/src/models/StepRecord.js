const mongoose = require('mongoose');

/**
 * StepRecord — stores daily step data for each user
 * One record per user per day
 */
const stepRecordSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    companyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
    },
    date: {
      type: String, // YYYY-MM-DD format for easy query
      required: true,
    },
    steps: {
      type: Number,
      default: 0,
      min: 0,
    },
    distance: {
      type: Number, // meters
      default: 0,
    },
    calories: {
      type: Number, // kcal
      default: 0,
    },
    // Hourly breakdown: { "08": 520, "09": 1200, ... }
    hourlySteps: {
      type: Map,
      of: Number,
      default: {},
    },
    syncedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index: one record per user per day
stepRecordSchema.index({ userId: 1, date: 1 }, { unique: true });

// Query indexes
stepRecordSchema.index({ companyId: 1, date: 1 });
stepRecordSchema.index({ userId: 1, date: -1 });

module.exports = mongoose.model('StepRecord', stepRecordSchema);
