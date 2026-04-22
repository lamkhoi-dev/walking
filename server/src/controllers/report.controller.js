const reportService = require('../services/report.service');
const { success, error } = require('../utils/response');

/**
 * Create a report
 * POST /api/v1/reports
 */
const createReport = async (req, res, next) => {
  try {
    const { targetType, targetId, reason, description } = req.body;

    if (!targetType || !targetId || !reason) {
      return error(res, 400, 'Vui lòng cung cấp đầy đủ thông tin báo cáo');
    }

    const report = await reportService.createReport({
      reporterId: req.user._id,
      targetType,
      targetId,
      reason,
      description,
    });

    return success(res, 201, 'Báo cáo đã được gửi', report);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

module.exports = { createReport };
