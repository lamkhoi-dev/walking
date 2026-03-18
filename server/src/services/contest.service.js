const Contest = require('../models/Contest');
const ContestLeaderboard = require('../models/ContestLeaderboard');
const Group = require('../models/Group');
const logger = require('../utils/logger');

class ContestService {
  /**
   * Create a new contest in a group
   */
  async createContest({ name, description, groupId, companyId, createdBy, startDate, endDate }) {
    // Validate dates - compare by date only (ignore time)
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const start = new Date(startDate);
    const startDay = new Date(start.getFullYear(), start.getMonth(), start.getDate());
    const end = new Date(endDate);

    if (startDay < today) {
      const err = new Error('Ngày bắt đầu phải từ hôm nay trở đi');
      err.statusCode = 400;
      throw err;
    }

    if (end <= start) {
      const err = new Error('Ngày kết thúc phải sau ngày bắt đầu');
      err.statusCode = 400;
      throw err;
    }

    // Check group exists and belongs to company
    const group = await Group.findOne({ _id: groupId, companyId, isActive: true });
    if (!group) {
      const err = new Error('Không tìm thấy nhóm');
      err.statusCode = 404;
      throw err;
    }

    logger.info(`Creating contest for group ${group.name}, members: ${group.members.length}`);
    logger.debug(`Group members: ${JSON.stringify(group.members)}`);

    // Check no active/upcoming contest in this group
    const existingContest = await Contest.findOne({
      groupId,
      status: { $in: ['upcoming', 'active'] },
    });

    if (existingContest) {
      const err = new Error('Nhóm đã có cuộc thi đang diễn ra hoặc sắp diễn ra');
      err.statusCode = 400;
      throw err;
    }

    // Create contest with all group members as participants
    const contest = await Contest.create({
      name,
      description: description || '',
      groupId,
      companyId,
      createdBy,
      startDate: start,
      endDate: end,
      status: 'upcoming',
      participants: group.members,
    });

    // Create leaderboard entries for each participant
    const leaderboardEntries = group.members.map((userId) => ({
      contestId: contest._id,
      userId,
      totalSteps: 0,
      dailySteps: {},
      rank: 0,
    }));

    await ContestLeaderboard.insertMany(leaderboardEntries);

    logger.info(`Contest created: ${contest._id} in group ${groupId}`);

    return contest.populate([
      { path: 'groupId', select: 'name avatar' },
      { path: 'createdBy', select: 'fullName avatar' },
    ]);
  }

  /**
   * Get contests for a group that user can see
   * User can see contest if they are a participant OR from the same company
   */
  async getContests(userId, companyId, groupId) {
    if (!groupId) {
      // If no groupId, get all contests where user is participant or same company
      const contests = await Contest.find({
        $or: [
          { participants: userId },
          { companyId: companyId }
        ]
      })
        .populate('groupId', 'name avatar')
        .populate('createdBy', 'fullName avatar')
        .sort({ startDate: -1 })
        .lean();
      return contests;
    }

    // If groupId specified, get contests for that group
    // User can see if they are participant OR from same company as contest
    const contests = await Contest.find({
      groupId,
      $or: [
        { participants: userId },
        { companyId: companyId }
      ]
    })
      .populate('groupId', 'name avatar')
      .populate('createdBy', 'fullName avatar')
      .sort({ startDate: -1 })
      .lean();

    return contests;
  }

  /**
   * Get a contest by ID
   */
  async getContestById(contestId) {
    const contest = await Contest.findById(contestId)
      .populate('groupId', 'name avatar totalMembers')
      .populate('createdBy', 'fullName avatar')
      .populate('participants', 'fullName avatar');

    if (!contest) {
      const err = new Error('Không tìm thấy cuộc thi');
      err.statusCode = 404;
      throw err;
    }

    return contest;
  }

  /**
   * Update a contest (only if upcoming)
   */
  async updateContest(contestId, updateData, companyId) {
    const contest = await Contest.findById(contestId);

    if (!contest) {
      const err = new Error('Không tìm thấy cuộc thi');
      err.statusCode = 404;
      throw err;
    }

    if (String(contest.companyId) !== String(companyId)) {
      const err = new Error('Không có quyền cập nhật cuộc thi này');
      err.statusCode = 403;
      throw err;
    }

    if (contest.status !== 'upcoming') {
      const err = new Error('Chỉ có thể cập nhật cuộc thi chưa bắt đầu');
      err.statusCode = 400;
      throw err;
    }

    // Only allow updating specific fields
    const allowedFields = ['name', 'description', 'startDate', 'endDate'];
    for (const key of Object.keys(updateData)) {
      if (allowedFields.includes(key)) {
        contest[key] = updateData[key];
      }
    }

    // Re-validate dates if changed
    if (updateData.startDate || updateData.endDate) {
      const now = new Date();
      if (contest.startDate < now) {
        const err = new Error('Ngày bắt đầu phải từ hôm nay trở đi');
        err.statusCode = 400;
        throw err;
      }
      if (contest.endDate <= contest.startDate) {
        const err = new Error('Ngày kết thúc phải sau ngày bắt đầu');
        err.statusCode = 400;
        throw err;
      }
    }

    await contest.save();

    return contest.populate([
      { path: 'groupId', select: 'name avatar' },
      { path: 'createdBy', select: 'fullName avatar' },
    ]);
  }

  /**
   * Cancel a contest
   */
  async cancelContest(contestId, companyId) {
    const contest = await Contest.findById(contestId);

    if (!contest) {
      const err = new Error('Không tìm thấy cuộc thi');
      err.statusCode = 404;
      throw err;
    }

    if (String(contest.companyId) !== String(companyId)) {
      const err = new Error('Không có quyền huỷ cuộc thi này');
      err.statusCode = 403;
      throw err;
    }

    if (!['upcoming', 'active'].includes(contest.status)) {
      const err = new Error('Chỉ có thể huỷ cuộc thi chưa bắt đầu hoặc đang diễn ra');
      err.statusCode = 400;
      throw err;
    }

    contest.status = 'cancelled';
    await contest.save();

    logger.info(`Contest cancelled: ${contestId}`);
    return contest;
  }

  /**
   * Get active contest for a group
   */
  async getActiveContestByGroup(groupId) {
    const contest = await Contest.findOne({
      groupId,
      status: 'active',
    })
      .populate('groupId', 'name avatar')
      .populate('createdBy', 'fullName avatar')
      .lean();

    return contest;
  }

  /**
   * Get leaderboard for a contest
   * @param {string} contestId
   * @param {string} [filterDate] - Optional date filter (YYYY-MM-DD). If provided, shows steps for that day only.
   */
  async getLeaderboard(contestId, filterDate = null) {
    const contest = await Contest.findById(contestId);
    if (!contest) {
      const err = new Error('Không tìm thấy cuộc thi');
      err.statusCode = 404;
      throw err;
    }

    // Sync: ensure all group members have leaderboard entries
    const group = await Group.findById(contest.groupId);
    if (group) {
      const existingEntries = await ContestLeaderboard.find({ contestId }).select('userId');
      const existingUserIds = existingEntries.map((e) => e.userId.toString());

      const missingMembers = group.members.filter(
        (memberId) => !existingUserIds.includes(memberId.toString())
      );

      if (missingMembers.length > 0) {
        // Add missing members to participants
        await Contest.findByIdAndUpdate(contestId, {
          $addToSet: { participants: { $each: missingMembers } },
        });

        // Create leaderboard entries
        const newEntries = missingMembers.map((userId) => ({
          contestId,
          userId,
          totalSteps: 0,
          dailySteps: {},
          rank: 0,
        }));
        await ContestLeaderboard.insertMany(newEntries);
        logger.info(`Synced ${missingMembers.length} missing members to contest ${contestId}`);
      }
    }

    const leaderboard = await ContestLeaderboard.find({ contestId })
      .populate('userId', 'fullName avatar')
      .lean();

    // If filterDate provided, use steps for that day; otherwise use totalSteps
    let processedLeaderboard;
    if (filterDate) {
      processedLeaderboard = leaderboard.map((entry) => {
        const dailySteps = entry.dailySteps instanceof Map
          ? entry.dailySteps.get(filterDate) || 0
          : (entry.dailySteps && entry.dailySteps[filterDate]) || 0;
        return {
          ...entry,
          displaySteps: dailySteps,
          filterDate,
        };
      });
    } else {
      processedLeaderboard = leaderboard.map((entry) => ({
        ...entry,
        displaySteps: entry.totalSteps,
        filterDate: null,
      }));
    }

    // Sort by displaySteps
    processedLeaderboard.sort((a, b) => b.displaySteps - a.displaySteps);

    // Assign ranks
    let currentRank = 1;
    for (let i = 0; i < processedLeaderboard.length; i++) {
      if (i > 0 && processedLeaderboard[i].displaySteps < processedLeaderboard[i - 1].displaySteps) {
        currentRank = i + 1;
      }
      processedLeaderboard[i].rank = currentRank;
    }

    return processedLeaderboard;
  }
}

module.exports = new ContestService();
