const mongoose = require('mongoose');

const userSettingsSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    dailyGoalSteps: {
      type: Number,
      default: 10000,
      min: 1000,
      max: 100000,
    },
    notifications: {
      chat: { type: Boolean, default: true },
      contest: { type: Boolean, default: true },
      dailyGoal: { type: Boolean, default: true },
      weeklyReport: { type: Boolean, default: true },
    },
    units: {
      type: String,
      enum: ['metric', 'imperial'],
      default: 'metric',
    },
  },
  {
    timestamps: true,
  }
);

userSettingsSchema.index({ userId: 1 }, { unique: true });

userSettingsSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('UserSettings', userSettingsSchema);
