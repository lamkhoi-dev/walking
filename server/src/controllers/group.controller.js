const groupService = require('../services/group.service');
const { success, error } = require('../utils/response');

/**
 * POST /groups — Create a new group (company_admin only)
 */
const createGroup = async (req, res, next) => {
  try {
    const { name, description, avatar, memberIds } = req.body;

    if (!name || name.trim().length === 0) {
      return error(res, 400, 'Tên nhóm là bắt buộc');
    }

    const group = await groupService.createGroup({
      name: name.trim(),
      description,
      avatar,
      memberIds: memberIds || [],
      companyId: req.user.companyId,
      createdBy: req.user._id,
    });

    return success(res, 201, 'Tạo nhóm thành công', group);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /groups — Get user's groups
 */
const getGroups = async (req, res, next) => {
  try {
    const isAdmin = req.user.role === 'company_admin';
    const groups = await groupService.getGroups(
      req.user._id,
      req.user.companyId,
      isAdmin
    );

    return success(res, 200, 'Lấy danh sách nhóm thành công', groups);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /groups/search?q= — Search groups by name
 */
const searchGroups = async (req, res, next) => {
  try {
    const { q } = req.query;
    const groups = await groupService.searchGroups(req.user.companyId, q);
    return success(res, 200, 'Tìm kiếm nhóm thành công', groups);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * GET /groups/:id — Get group detail
 */
const getGroupById = async (req, res, next) => {
  try {
    const group = await groupService.getGroupById(req.params.id);

    // Ensure user's company matches group's company
    if (group.companyId.toString() !== req.user.companyId.toString()) {
      return error(res, 403, 'Bạn không có quyền xem nhóm này');
    }

    return success(res, 200, 'Lấy thông tin nhóm thành công', group);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * PUT /groups/:id — Update group (company_admin only)
 */
const updateGroup = async (req, res, next) => {
  try {
    const group = await groupService.updateGroup(
      req.params.id,
      req.body,
      req.user._id,
      req.user.companyId
    );
    return success(res, 200, 'Cập nhật nhóm thành công', group);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * DELETE /groups/:id — Delete group (company_admin only)
 */
const deleteGroup = async (req, res, next) => {
  try {
    await groupService.deleteGroup(req.params.id, req.user.companyId);
    return success(res, 200, 'Xóa nhóm thành công');
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * POST /groups/:id/members — Add members (company_admin only)
 */
const addMembers = async (req, res, next) => {
  try {
    const { memberIds } = req.body;

    if (!memberIds || !Array.isArray(memberIds) || memberIds.length === 0) {
      return error(res, 400, 'Danh sách thành viên là bắt buộc');
    }

    const group = await groupService.addMembers(
      req.params.id,
      memberIds,
      req.user.companyId
    );

    return success(res, 200, 'Thêm thành viên thành công', group);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * DELETE /groups/:id/members/:userId — Remove member (company_admin only)
 */
const removeMember = async (req, res, next) => {
  try {
    const group = await groupService.removeMember(
      req.params.id,
      req.params.userId,
      req.user.companyId
    );
    return success(res, 200, 'Xóa thành viên thành công', group);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

/**
 * POST /groups/join/:groupId — Join group by QR code
 */
const joinByQR = async (req, res, next) => {
  try {
    const group = await groupService.joinByQR(
      req.params.groupId,
      req.user._id,
      req.user.companyId
    );
    return success(res, 200, 'Tham gia nhóm thành công', group);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.statusCode, err.message);
    }
    next(err);
  }
};

module.exports = {
  createGroup,
  getGroups,
  searchGroups,
  getGroupById,
  updateGroup,
  deleteGroup,
  addMembers,
  removeMember,
  joinByQR,
};
