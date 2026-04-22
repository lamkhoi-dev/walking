const Report = require('../models/Report');
const logger = require('../utils/logger');

/**
 * Create a content report
 */
const createReport = async ({ reporterId, targetType, targetId, reason, description }) => {
  // Check for duplicate report
  const existing = await Report.findOne({ reporterId, targetType, targetId });
  if (existing) {
    const err = new Error('Bạn đã báo cáo nội dung này rồi');
    err.statusCode = 409;
    throw err;
  }

  const report = await Report.create({
    reporterId,
    targetType,
    targetId,
    reason,
    description: description || '',
  });

  logger.info(`Report created: ${targetType}/${targetId} by user ${reporterId} (${reason})`);
  return report;
};

module.exports = { createReport };
