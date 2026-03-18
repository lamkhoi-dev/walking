const settingsService = require('../services/settings.service');
const { success, error } = require('../utils/response');

/**
 * GET /settings — Get user settings
 */
const getSettings = async (req, res, next) => {
  try {
    const settings = await settingsService.getSettings(req.user._id);
    return success(res, 200, 'Lấy cài đặt thành công', settings);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * PUT /settings — Update user settings
 */
const updateSettings = async (req, res, next) => {
  try {
    const settings = await settingsService.updateSettings(req.user._id, req.body);
    return success(res, 200, 'Cập nhật cài đặt thành công', settings);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

module.exports = {
  getSettings,
  updateSettings,
};
