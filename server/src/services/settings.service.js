const UserSettings = require('../models/UserSettings');
const logger = require('../utils/logger');

class SettingsService {
  /**
   * Get user settings — creates default if not exists
   */
  async getSettings(userId) {
    let settings = await UserSettings.findOne({ userId }).lean();

    if (!settings) {
      settings = await UserSettings.create({ userId });
      settings = settings.toJSON();
      logger.debug(`Default settings created for user=${userId}`);
    }

    return settings;
  }

  /**
   * Update user settings (partial update)
   */
  async updateSettings(userId, data) {
    const updateData = {};

    // Daily goal
    if (data.dailyGoalSteps !== undefined) {
      const goal = Number(data.dailyGoalSteps);
      if (isNaN(goal) || goal < 1000 || goal > 100000) {
        const err = new Error('Mục tiêu bước phải từ 1.000 đến 100.000');
        err.statusCode = 400;
        throw err;
      }
      updateData.dailyGoalSteps = goal;
    }

    // Notification preferences
    if (data.notifications && typeof data.notifications === 'object') {
      const allowed = ['chat', 'contest', 'dailyGoal', 'weeklyReport'];
      for (const key of allowed) {
        if (data.notifications[key] !== undefined) {
          updateData[`notifications.${key}`] = Boolean(data.notifications[key]);
        }
      }
    }

    // Units
    if (data.units !== undefined) {
      if (!['metric', 'imperial'].includes(data.units)) {
        const err = new Error('Đơn vị phải là "metric" hoặc "imperial"');
        err.statusCode = 400;
        throw err;
      }
      updateData.units = data.units;
    }

    if (Object.keys(updateData).length === 0) {
      const err = new Error('Không có dữ liệu để cập nhật');
      err.statusCode = 400;
      throw err;
    }

    const settings = await UserSettings.findOneAndUpdate(
      { userId },
      { $set: updateData },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    ).lean();

    logger.debug(`Settings updated for user=${userId}`);
    return settings;
  }
}

module.exports = new SettingsService();
