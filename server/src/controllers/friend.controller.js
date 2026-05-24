const friendService = require('../services/friend.service');
const logger = require('../utils/logger');

const sendRequest = async (req, res) => {
  try {
    const result = await friendService.sendRequest(req.user.id, req.params.userId);
    const message = result.autoAccepted
      ? 'Đã trở thành bạn bè (đối phương đã gửi lời mời trước đó)'
      : 'Đã gửi lời mời kết bạn';
    res.status(201).json({ success: true, message, data: result.friendship });
  } catch (err) {
    logger.error('sendRequest error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const acceptRequest = async (req, res) => {
  try {
    const friendship = await friendService.acceptRequest(req.user.id, req.params.friendshipId);
    res.json({ success: true, message: 'Đã chấp nhận lời mời kết bạn', data: friendship });
  } catch (err) {
    logger.error('acceptRequest error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const rejectRequest = async (req, res) => {
  try {
    await friendService.rejectRequest(req.user.id, req.params.friendshipId);
    res.json({ success: true, message: 'Đã từ chối lời mời kết bạn' });
  } catch (err) {
    logger.error('rejectRequest error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const cancelRequest = async (req, res) => {
  try {
    await friendService.cancelRequest(req.user.id, req.params.friendshipId);
    res.json({ success: true, message: 'Đã huỷ lời mời kết bạn' });
  } catch (err) {
    logger.error('cancelRequest error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const unfriend = async (req, res) => {
  try {
    await friendService.unfriend(req.user.id, req.params.friendId);
    res.json({ success: true, message: 'Đã huỷ kết bạn' });
  } catch (err) {
    logger.error('unfriend error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const getFriends = async (req, res) => {
  try {
    const { page, limit, search } = req.query;
    const result = await friendService.getFriends(req.user.id, {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      search,
    });
    res.json({ success: true, data: result });
  } catch (err) {
    logger.error('getFriends error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const getFriendRequests = async (req, res) => {
  try {
    const { page, limit } = req.query;
    const result = await friendService.getFriendRequests(req.user.id, {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });
    res.json({ success: true, data: result });
  } catch (err) {
    logger.error('getFriendRequests error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const getSentRequests = async (req, res) => {
  try {
    const { page, limit } = req.query;
    const result = await friendService.getSentRequests(req.user.id, {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });
    res.json({ success: true, data: result });
  } catch (err) {
    logger.error('getSentRequests error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const getFriendshipStatus = async (req, res) => {
  try {
    const result = await friendService.getFriendshipStatus(req.user.id, req.params.userId);
    res.json({ success: true, data: result });
  } catch (err) {
    logger.error('getFriendshipStatus error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const searchUsers = async (req, res) => {
  try {
    const { q, page, limit } = req.query;
    if (!q || q.trim().length < 1) {
      return res.json({ success: true, data: { users: [], pagination: { page: 1, limit: 20, total: 0, pages: 0 } } });
    }
    const result = await friendService.searchUsers(q.trim(), req.user.id, {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });
    res.json({ success: true, data: result });
  } catch (err) {
    logger.error('searchUsers error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

const getFriendCount = async (req, res) => {
  try {
    const userId = req.params.userId || req.user.id;
    const count = await friendService.getFriendCount(userId);
    res.json({ success: true, data: { count } });
  } catch (err) {
    logger.error('getFriendCount error:', err);
    res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
};

module.exports = {
  sendRequest,
  acceptRequest,
  rejectRequest,
  cancelRequest,
  unfriend,
  getFriends,
  getFriendRequests,
  getSentRequests,
  getFriendshipStatus,
  searchUsers,
  getFriendCount,
};
