const contestService = require('../services/contest.service');
const { success, error } = require('../utils/response');

/**
 * POST / — create a new contest (company_admin only)
 */
const createContest = async (req, res, next) => {
  try {
    const { name, description, groupId, startDate, endDate } = req.body;

    if (!name || !groupId || !startDate || !endDate) {
      return error(res, 400, 'Vui lòng cung cấp đầy đủ thông tin');
    }

    const contest = await contestService.createContest({
      name,
      description,
      groupId,
      companyId: req.user.companyId,
      createdBy: req.user._id,
      startDate,
      endDate,
    });

    return success(res, 201, 'Tạo cuộc thi thành công', contest);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET / — list contests for the user
 * Query: ?groupId=xxx
 */
const getContests = async (req, res, next) => {
  try {
    const { groupId } = req.query;
    const contests = await contestService.getContests(req.user._id, req.user.companyId, groupId);
    return success(res, 200, 'Lấy danh sách cuộc thi thành công', contests);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /:id — get contest by ID
 */
const getContestById = async (req, res, next) => {
  try {
    const contest = await contestService.getContestById(req.params.id);
    return success(res, 200, 'Lấy thông tin cuộc thi thành công', contest);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * PUT /:id — update contest (company_admin only, upcoming only)
 */
const updateContest = async (req, res, next) => {
  try {
    const { name, description, startDate, endDate } = req.body;

    const contest = await contestService.updateContest(
      req.params.id,
      { name, description, startDate, endDate },
      req.user.companyId
    );

    return success(res, 200, 'Cập nhật cuộc thi thành công', contest);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * DELETE /:id — cancel contest (company_admin only)
 */
const cancelContest = async (req, res, next) => {
  try {
    const contest = await contestService.cancelContest(
      req.params.id,
      req.user.companyId
    );

    return success(res, 200, 'Huỷ cuộc thi thành công', contest);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /:id/leaderboard — get leaderboard for a contest
 * Query: ?date=YYYY-MM-DD (optional, filter by specific day)
 */
const getLeaderboard = async (req, res, next) => {
  try {
    const { date } = req.query;
    const leaderboard = await contestService.getLeaderboard(req.params.id, date || null);
    return success(res, 200, 'Lấy bảng xếp hạng thành công', leaderboard);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /group/:groupId/active — get active contest for a group
 */
const getActiveContestByGroup = async (req, res, next) => {
  try {
    const contest = await contestService.getActiveContestByGroup(req.params.groupId);
    return success(res, 200, 'Thành công', contest);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createContest,
  getContests,
  getContestById,
  updateContest,
  cancelContest,
  getLeaderboard,
  getActiveContestByGroup,
};
