const StepRecord = require('../models/StepRecord');
const logger = require('../utils/logger');

class StepService {
  /**
   * Sync steps from client — upsert for a given date
   * @param {string} userId
   * @param {string} companyId
   * @param {object} data - { date, steps, hourlySteps }
   */
  async syncSteps(userId, companyId, { date, steps, hourlySteps }) {
    if (!date) {
      const err = new Error('Ngày là bắt buộc');
      err.statusCode = 400;
      throw err;
    }

    if (typeof steps !== 'number' || steps < 0) {
      const err = new Error('Số bước không hợp lệ');
      err.statusCode = 400;
      throw err;
    }

    // Calculate derived metrics
    const distance = Math.round(steps * 0.762); // average stride ~0.762m
    const calories = Math.round(steps * 0.04 * 100) / 100; // ~0.04 kcal per step

    const record = await StepRecord.findOneAndUpdate(
      { userId, date },
      {
        $set: {
          steps,
          distance,
          calories,
          hourlySteps: hourlySteps || {},
          companyId,
          syncedAt: new Date(),
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    logger.debug(`Steps synced: user=${userId}, date=${date}, steps=${steps}`);
    return record;
  }

  /**
   * Get today's step record for a user
   */
  async getToday(userId) {
    const today = this._getTodayDateStr();
    const record = await StepRecord.findOne({ userId, date: today }).lean();

    return record || { steps: 0, distance: 0, calories: 0, date: today };
  }

  /**
   * Get step history for a user in a date range
   * @param {string} userId
   * @param {string} fromDate - YYYY-MM-DD
   * @param {string} toDate - YYYY-MM-DD
   */
  async getHistory(userId, fromDate, toDate) {
    const filter = { userId };

    if (fromDate && toDate) {
      filter.date = { $gte: fromDate, $lte: toDate };
    } else if (fromDate) {
      filter.date = { $gte: fromDate };
    } else if (toDate) {
      filter.date = { $lte: toDate };
    }

    const records = await StepRecord.find(filter)
      .sort({ date: -1 })
      .lean();

    return records;
  }

  /**
   * Get step statistics for a user
   */
  async getStats(userId) {
    const today = this._getTodayDateStr();
    const weekAgo = this._getDateStr(-7);
    const monthAgo = this._getDateStr(-30);

    // This week's records
    const weekRecords = await StepRecord.find({
      userId,
      date: { $gte: weekAgo, $lte: today },
    }).lean();

    // This month's records
    const monthRecords = await StepRecord.find({
      userId,
      date: { $gte: monthAgo, $lte: today },
    }).lean();

    const weekTotal = weekRecords.reduce((sum, r) => sum + (r.steps || 0), 0);
    const monthTotal = monthRecords.reduce((sum, r) => sum + (r.steps || 0), 0);

    const weekDays = weekRecords.length || 1;
    const monthDays = monthRecords.length || 1;

    // Today's record
    const todayRecord = weekRecords.find((r) => r.date === today);

    return {
      today: {
        steps: todayRecord?.steps || 0,
        distance: todayRecord?.distance || 0,
        calories: todayRecord?.calories || 0,
      },
      week: {
        totalSteps: weekTotal,
        totalDistance: Math.round(weekTotal * 0.762),
        totalCalories: Math.round(weekTotal * 0.04 * 100) / 100,
        avgStepsPerDay: Math.round(weekTotal / weekDays),
        daysTracked: weekDays,
      },
      month: {
        totalSteps: monthTotal,
        totalDistance: Math.round(monthTotal * 0.762),
        totalCalories: Math.round(monthTotal * 0.04 * 100) / 100,
        avgStepsPerDay: Math.round(monthTotal / monthDays),
        daysTracked: monthDays,
      },
    };
  }

  /**
   * Get today's date string in YYYY-MM-DD format
   */
  _getTodayDateStr() {
    return new Date().toISOString().split('T')[0];
  }

  /**
   * Get a date string offset by `days` from today
   */
  _getDateStr(daysOffset) {
    const d = new Date();
    d.setDate(d.getDate() + daysOffset);
    return d.toISOString().split('T')[0];
  }
}

module.exports = new StepService();
