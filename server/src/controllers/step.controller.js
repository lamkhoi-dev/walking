const stepService = require('../services/step.service');
const { success, error } = require('../utils/response');

/**
 * POST /steps/sync — Sync step data from client
 */
const syncSteps = async (req, res, next) => {
  try {
    const { date, steps, hourlySteps } = req.body;

    if (!date) {
      return error(res, 400, 'Ngày là bắt buộc');
    }

    if (typeof steps !== 'number' || steps < 0) {
      return error(res, 400, 'Số bước không hợp lệ');
    }

    const record = await stepService.syncSteps(
      req.user._id,
      req.user.companyId,
      { date, steps, hourlySteps }
    );

    return success(res, 200, 'Đồng bộ bước thành công', record);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /steps/today — Get today's step data
 */
const getToday = async (req, res, next) => {
  try {
    const data = await stepService.getToday(req.user._id);
    return success(res, 200, 'Lấy dữ liệu bước hôm nay thành công', data);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /steps/history?from=YYYY-MM-DD&to=YYYY-MM-DD — Get step history
 */
const getHistory = async (req, res, next) => {
  try {
    const { from, to } = req.query;
    const records = await stepService.getHistory(req.user._id, from, to);
    return success(res, 200, 'Lấy lịch sử bước thành công', records);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /steps/stats — Get step statistics (today, week, month)
 */
const getStats = async (req, res, next) => {
  try {
    const stats = await stepService.getStats(req.user._id);
    return success(res, 200, 'Lấy thống kê bước thành công', stats);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

module.exports = {
  syncSteps,
  getToday,
  getHistory,
  getStats,
};
