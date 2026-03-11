const Group = require('../models/Group');
const escapeRegex = require('../utils/escapeRegex');
const User = require('../models/User');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const logger = require('../utils/logger');

class GroupService {
  /**
   * Create a new group
   */
  async createGroup({ name, description, avatar, memberIds = [], companyId, createdBy }) {
    // Validate memberIds are active users (no company restriction)
    if (memberIds.length > 0) {
      const validMembers = await User.countDocuments({
        _id: { $in: memberIds },
        isActive: true,
      });
      if (validMembers !== memberIds.length) {
        const err = new Error('Một số thành viên không tồn tại hoặc đã bị vô hiệu hóa');
        err.statusCode = 400;
        throw err;
      }
    }

    // Ensure creator is included in members
    const memberSet = new Set(memberIds.map((id) => id.toString()));
    memberSet.add(createdBy.toString());
    const allMembers = [...memberSet];

    // Create group
    const group = await Group.create({
      name,
      description: description || undefined,
      avatar: avatar || undefined,
      companyId,
      createdBy,
      members: allMembers,
      totalMembers: allMembers.length,
    });

    // Create conversation for this group
    const conversation = await Conversation.create({
      type: 'group',
      groupId: group._id,
      participants: allMembers,
      companyId,
    });

    // Link conversation to group
    group.conversationId = conversation._id;
    await group.save();

    // System message
    await Message.create({
      conversationId: conversation._id,
      type: 'system',
      content: 'Nhóm đã được tạo',
    });

    logger.info(`Group created: ${name} (company: ${companyId})`);

    return group.populate([
      { path: 'members', select: '_id fullName avatar role' },
      { path: 'createdBy', select: '_id fullName avatar' },
    ]);
  }

  /**
   * Get groups for a user
   */
  async getGroups(userId, companyId, isAdmin = false) {
    const filter = { isActive: true };

    if (isAdmin && companyId) {
      // Admin sees all groups in their company
      filter.companyId = companyId;
    } else {
      // Regular members only see groups they belong to
      filter.members = userId;
    }

    const groups = await Group.find(filter)
      .populate('members', '_id fullName avatar role')
      .populate('createdBy', '_id fullName avatar')
      .populate({
        path: 'conversationId',
        populate: {
          path: 'lastMessage',
          select: 'content type senderId createdAt',
          populate: { path: 'senderId', select: 'fullName' },
        },
      })
      .sort({ updatedAt: -1 })
      .lean();

    return groups;
  }

  /**
   * Get group by ID
   */
  async getGroupById(groupId) {
    const group = await Group.findOne({ _id: groupId, isActive: true })
      .populate('members', '_id fullName email phone avatar role')
      .populate('createdBy', '_id fullName avatar')
      .lean();

    if (!group) {
      const err = new Error('Không tìm thấy nhóm');
      err.statusCode = 404;
      throw err;
    }

    return group;
  }

  /**
   * Update group (name, description, avatar)
   */
  async updateGroup(groupId, updateData, userId, companyId) {
    const group = await Group.findOne({ _id: groupId, isActive: true });
    if (!group) {
      const err = new Error('Không tìm thấy nhóm');
      err.statusCode = 404;
      throw err;
    }

    // Verify group belongs to admin's company
    if (group.companyId.toString() !== companyId.toString()) {
      const err = new Error('Bạn không có quyền cập nhật nhóm này');
      err.statusCode = 403;
      throw err;
    }

    // Only allow updating name, description, avatar
    const allowed = ['name', 'description', 'avatar'];
    const updates = {};
    for (const key of allowed) {
      if (updateData[key] !== undefined) {
        updates[key] = updateData[key];
      }
    }

    Object.assign(group, updates);
    await group.save();

    return group.populate([
      { path: 'members', select: '_id fullName avatar role' },
      { path: 'createdBy', select: '_id fullName avatar' },
    ]);
  }

  /**
   * Soft delete group
   */
  async deleteGroup(groupId, companyId) {
    const group = await Group.findOne({ _id: groupId, isActive: true });
    if (!group) {
      const err = new Error('Không tìm thấy nhóm');
      err.statusCode = 404;
      throw err;
    }

    // Verify group belongs to admin's company
    if (group.companyId.toString() !== companyId.toString()) {
      const err = new Error('Bạn không có quyền xóa nhóm này');
      err.statusCode = 403;
      throw err;
    }

    group.isActive = false;
    await group.save();

    // Also deactivate conversation
    if (group.conversationId) {
      await Conversation.findByIdAndUpdate(group.conversationId, { isActive: false });
    }

    logger.info(`Group deleted: ${group.name} (${groupId})`);
    return group;
  }

  /**
   * Add members to a group
   */
  async addMembers(groupId, memberIds, companyId) {
    const group = await Group.findOne({ _id: groupId, isActive: true });
    if (!group) {
      const err = new Error('Không tìm thấy nhóm');
      err.statusCode = 404;
      throw err;
    }

    // Validate all members are active users (no company restriction)
    const validMembers = await User.find({
      _id: { $in: memberIds },
      isActive: true,
    }).select('_id fullName');

    if (validMembers.length !== memberIds.length) {
      const err = new Error('Một số thành viên không tồn tại hoặc đã bị vô hiệu hóa');
      err.statusCode = 400;
      throw err;
    }

    // Filter out already existing members
    const existingIds = group.members.map((m) => m.toString());
    const newMembers = validMembers.filter((m) => !existingIds.includes(m._id.toString()));

    if (newMembers.length === 0) {
      const err = new Error('Tất cả thành viên đã có trong nhóm');
      err.statusCode = 400;
      throw err;
    }

    const newMemberIds = newMembers.map((m) => m._id);
    group.members.push(...newMemberIds);
    group.totalMembers = group.members.length;
    await group.save();

    // Also add to conversation participants
    if (group.conversationId) {
      await Conversation.findByIdAndUpdate(group.conversationId, {
        $addToSet: { participants: { $each: newMemberIds } },
      });
    }

    // System message
    const names = newMembers.map((m) => m.fullName).join(', ');
    if (group.conversationId) {
      await Message.create({
        conversationId: group.conversationId,
        type: 'system',
        content: `${names} đã được thêm vào nhóm`,
      });
    }

    logger.info(`Added ${newMembers.length} members to group ${group.name}`);

    return group.populate('members', '_id fullName avatar role');
  }

  /**
   * Remove a member from group
   */
  async removeMember(groupId, userId, companyId) {
    const group = await Group.findOne({ _id: groupId, isActive: true });
    if (!group) {
      const err = new Error('Không tìm thấy nhóm');
      err.statusCode = 404;
      throw err;
    }

    // Verify group belongs to admin's company
    if (companyId && group.companyId.toString() !== companyId.toString()) {
      const err = new Error('Bạn không có quyền quản lý nhóm này');
      err.statusCode = 403;
      throw err;
    }

    // Cannot remove creator
    if (group.createdBy.toString() === userId.toString()) {
      const err = new Error('Không thể xóa người tạo nhóm');
      err.statusCode = 400;
      throw err;
    }

    const memberIndex = group.members.findIndex((m) => m.toString() === userId.toString());
    if (memberIndex === -1) {
      const err = new Error('Thành viên không có trong nhóm');
      err.statusCode = 400;
      throw err;
    }

    // Get user name for system message
    const user = await User.findById(userId).select('fullName');

    group.members.splice(memberIndex, 1);
    group.totalMembers = group.members.length;
    await group.save();

    // Remove from conversation participants
    if (group.conversationId) {
      await Conversation.findByIdAndUpdate(group.conversationId, {
        $pull: { participants: userId },
      });

      // System message
      await Message.create({
        conversationId: group.conversationId,
        type: 'system',
        content: `${user?.fullName || 'Thành viên'} đã rời nhóm`,
      });
    }

    return group.populate('members', '_id fullName avatar role');
  }

  /**
   * Search groups by name within a company
   */
  async searchGroups(companyId, query) {
    if (!query || query.trim().length === 0) {
      return [];
    }

    const filter = {
      isActive: true,
      name: { $regex: escapeRegex(query.trim()), $options: 'i' },
    };

    // If user has a company, search within company; otherwise search all
    if (companyId) {
      filter.companyId = companyId;
    }

    const groups = await Group.find(filter)
      .populate('members', '_id fullName avatar')
      .populate('createdBy', '_id fullName avatar')
      .sort({ name: 1 })
      .limit(20)
      .lean();

    return groups;
  }

  /**
   * Join group by QR code (groupId)
   */
  async joinByQR(groupId, userId, companyId) {
    const group = await Group.findOne({ _id: groupId, isActive: true });
    if (!group) {
      const err = new Error('Không tìm thấy nhóm');
      err.statusCode = 404;
      throw err;
    }

    // Check already a member
    if (group.members.some((m) => m.toString() === userId.toString())) {
      const err = new Error('Bạn đã là thành viên nhóm này');
      err.statusCode = 400;
      throw err;
    }

    // Get user name
    const user = await User.findById(userId).select('fullName');

    group.members.push(userId);
    group.totalMembers = group.members.length;
    await group.save();

    // Add to conversation
    if (group.conversationId) {
      await Conversation.findByIdAndUpdate(group.conversationId, {
        $addToSet: { participants: userId },
      });

      await Message.create({
        conversationId: group.conversationId,
        type: 'system',
        content: `${user?.fullName || 'Thành viên'} đã tham gia nhóm`,
      });
    }

    return group.populate([
      { path: 'members', select: '_id fullName avatar role' },
      { path: 'createdBy', select: '_id fullName avatar' },
    ]);
  }
}

module.exports = new GroupService();
