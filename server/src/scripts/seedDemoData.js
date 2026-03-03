/**
 * Seed Demo Data script
 * Creates sample companies, users, groups, conversations, messages,
 * contests, step records, and leaderboard entries for testing.
 *
 * Usage: node src/scripts/seedDemoData.js
 *
 * ⚠️  This will clear existing data (except super_admin). Use with caution!
 */

const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const User = require('../models/User');
const Company = require('../models/Company');
const Group = require('../models/Group');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const StepRecord = require('../models/StepRecord');
const Contest = require('../models/Contest');
const ContestLeaderboard = require('../models/ContestLeaderboard');
const config = require('../config/env');
const generateCompanyCode = require('../utils/generateCompanyCode');

const PASSWORD = 'Test@123';

async function seedDemoData() {
  try {
    await mongoose.connect(config.mongodbUri);
    console.log('✅ Connected to MongoDB');

    // === Clean up existing demo data (keep super_admin) ===
    console.log('\n🧹 Cleaning up existing data...');
    await ContestLeaderboard.deleteMany({});
    await Contest.deleteMany({});
    await StepRecord.deleteMany({});
    await Message.deleteMany({});
    await Conversation.deleteMany({});
    await Group.deleteMany({});
    await Company.deleteMany({});
    await User.deleteMany({ role: { $ne: 'super_admin' } });
    console.log('   Done.');

    // ===================================================
    // COMPANY 1: Công ty ABC
    // ===================================================
    console.log('\n🏢 Creating Company 1: Công ty ABC...');
    const company1 = await Company.create({
      name: 'Công ty ABC',
      email: 'admin@abc.vn',
      phone: '0901234567',
      address: '123 Nguyễn Huệ, Q1, TP.HCM',
      description: 'Công ty công nghệ hàng đầu Việt Nam',
      code: generateCompanyCode(),
      status: 'approved',
      totalMembers: 6,
    });

    // Admin for Company 1
    const admin1 = await User.create({
      email: 'admin@abc.vn',
      phone: '0901234567',
      password: PASSWORD,
      fullName: 'Nguyễn Văn Admin',
      role: 'company_admin',
      companyId: company1._id,
      companyCode: company1.code,
      isActive: true,
    });
    company1.adminId = admin1._id;
    await company1.save();

    // Members for Company 1
    const members1 = [];
    const memberData1 = [
      { fullName: 'Trần Thị Hoa', email: 'hoa@abc.vn', phone: '0911111111' },
      { fullName: 'Lê Minh Tuấn', email: 'tuan@abc.vn', phone: '0911111112' },
      { fullName: 'Phạm Ngọc Lan', email: 'lan@abc.vn', phone: '0911111113' },
      { fullName: 'Võ Thanh Hùng', email: 'hung@abc.vn', phone: '0911111114' },
      { fullName: 'Đặng Thu Hà', email: 'ha@abc.vn', phone: '0911111115' },
    ];

    for (const m of memberData1) {
      const user = await User.create({
        ...m,
        password: PASSWORD,
        role: 'member',
        companyId: company1._id,
        companyCode: company1.code,
        isActive: true,
      });
      members1.push(user);
    }

    console.log(`   Admin: ${admin1.email}`);
    console.log(`   Members: ${members1.map((m) => m.fullName).join(', ')}`);

    // ===================================================
    // COMPANY 2: Công ty XYZ
    // ===================================================
    console.log('\n🏢 Creating Company 2: Công ty XYZ...');
    const company2 = await Company.create({
      name: 'Công ty XYZ',
      email: 'admin@xyz.vn',
      phone: '0902345678',
      address: '456 Lê Lợi, Q1, TP.HCM',
      description: 'Startup về sức khỏe và wellness',
      code: generateCompanyCode(),
      status: 'approved',
      totalMembers: 4,
    });

    const admin2 = await User.create({
      email: 'admin@xyz.vn',
      phone: '0902345678',
      password: PASSWORD,
      fullName: 'Phạm Quốc Bảo',
      role: 'company_admin',
      companyId: company2._id,
      companyCode: company2.code,
      isActive: true,
    });
    company2.adminId = admin2._id;
    await company2.save();

    const members2 = [];
    const memberData2 = [
      { fullName: 'Nguyễn Thị Mai', email: 'mai@xyz.vn', phone: '0922222221' },
      { fullName: 'Trần Đức Long', email: 'long@xyz.vn', phone: '0922222222' },
      { fullName: 'Hoàng Anh Thư', email: 'thu@xyz.vn', phone: '0922222223' },
    ];

    for (const m of memberData2) {
      const user = await User.create({
        ...m,
        password: PASSWORD,
        role: 'member',
        companyId: company2._id,
        companyCode: company2.code,
        isActive: true,
      });
      members2.push(user);
    }

    console.log(`   Admin: ${admin2.email}`);
    console.log(`   Members: ${members2.map((m) => m.fullName).join(', ')}`);

    // ===================================================
    // GROUPS for Company 1
    // ===================================================
    console.log('\n👥 Creating Groups for Company 1...');

    // Group 1: Phòng Kỹ thuật
    const allMembers1 = [admin1._id, ...members1.map((m) => m._id)];
    const conv1 = await Conversation.create({
      type: 'group',
      participants: allMembers1,
      companyId: company1._id,
    });
    const group1 = await Group.create({
      name: 'Phòng Kỹ thuật',
      description: 'Nhóm đi bộ của phòng kỹ thuật',
      companyId: company1._id,
      createdBy: admin1._id,
      members: allMembers1,
      totalMembers: allMembers1.length,
      conversationId: conv1._id,
    });
    conv1.groupId = group1._id;
    await conv1.save();

    // Group 2: Team Marketing (subset)
    const marketingMembers = [admin1._id, members1[0]._id, members1[1]._id, members1[4]._id];
    const conv2 = await Conversation.create({
      type: 'group',
      participants: marketingMembers,
      companyId: company1._id,
    });
    const group2 = await Group.create({
      name: 'Team Marketing',
      description: 'Nhóm thử thách đi bộ marketing',
      companyId: company1._id,
      createdBy: admin1._id,
      members: marketingMembers,
      totalMembers: marketingMembers.length,
      conversationId: conv2._id,
    });
    conv2.groupId = group2._id;
    await conv2.save();

    console.log(`   Group 1: ${group1.name} (${group1.totalMembers} members)`);
    console.log(`   Group 2: ${group2.name} (${group2.totalMembers} members)`);

    // ===================================================
    // GROUP for Company 2
    // ===================================================
    console.log('\n👥 Creating Group for Company 2...');
    const allMembers2 = [admin2._id, ...members2.map((m) => m._id)];
    const conv3 = await Conversation.create({
      type: 'group',
      participants: allMembers2,
      companyId: company2._id,
    });
    const group3 = await Group.create({
      name: 'Healthy Squad',
      description: 'Cùng nhau đi bộ mỗi ngày!',
      companyId: company2._id,
      createdBy: admin2._id,
      members: allMembers2,
      totalMembers: allMembers2.length,
      conversationId: conv3._id,
    });
    conv3.groupId = group3._id;
    await conv3.save();
    console.log(`   Group: ${group3.name} (${group3.totalMembers} members)`);

    // ===================================================
    // MESSAGES — sample chat messages
    // ===================================================
    console.log('\n💬 Creating sample messages...');

    const sampleMessages = [
      { senderId: admin1._id, content: 'Chào cả nhà! Tuần này mình đi bộ thật nhiều nhé 💪', conversationId: conv1._id },
      { senderId: members1[0]._id, content: 'Hay quá anh! Em đang cố gắng 10,000 bước/ngày', conversationId: conv1._id },
      { senderId: members1[1]._id, content: 'Hôm nay em đi được 8,500 bước rồi 🎉', conversationId: conv1._id },
      { senderId: members1[2]._id, content: 'Cuộc thi tuần này ai thắng nhỉ?', conversationId: conv1._id },
      { senderId: admin1._id, content: 'Team marketing cùng cố lên nào!', conversationId: conv2._id },
      { senderId: members1[0]._id, content: 'Tối nay em đi bộ thêm 30 phút nữa', conversationId: conv2._id },
      { senderId: admin2._id, content: 'Welcome to Healthy Squad! 🏃‍♂️', conversationId: conv3._id },
      { senderId: members2[0]._id, content: 'Cảm ơn anh! Em sẵn sàng rồi!', conversationId: conv3._id },
    ];

    let lastMsg1 = null;
    let lastMsg2 = null;
    let lastMsg3 = null;
    for (const msgData of sampleMessages) {
      const msg = await Message.create({
        ...msgData,
        type: 'text',
        readBy: [msgData.senderId],
      });
      if (msgData.conversationId.equals(conv1._id)) lastMsg1 = msg;
      if (msgData.conversationId.equals(conv2._id)) lastMsg2 = msg;
      if (msgData.conversationId.equals(conv3._id)) lastMsg3 = msg;
    }

    // Update lastMessage on conversations
    if (lastMsg1) { conv1.lastMessage = lastMsg1._id; await conv1.save(); }
    if (lastMsg2) { conv2.lastMessage = lastMsg2._id; await conv2.save(); }
    if (lastMsg3) { conv3.lastMessage = lastMsg3._id; await conv3.save(); }

    console.log(`   Created ${sampleMessages.length} messages`);

    // ===================================================
    // STEP RECORDS — last 7 days of data
    // ===================================================
    console.log('\n👟 Creating step records for last 7 days...');

    const today = new Date();
    let stepRecordCount = 0;

    const allUsers = [admin1, ...members1, admin2, ...members2];

    for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
      const d = new Date(today);
      d.setDate(d.getDate() - dayOffset);
      const dateStr = d.toISOString().split('T')[0]; // YYYY-MM-DD

      for (const user of allUsers) {
        const baseSteps = Math.floor(Math.random() * 8000) + 3000; // 3000-11000
        const hourlySteps = {};
        let remaining = baseSteps;
        for (let h = 7; h <= 21; h++) {
          const hourKey = h.toString().padStart(2, '0');
          const chunk = h >= 7 && h <= 9 ? Math.floor(remaining * 0.15) :
            h >= 17 && h <= 19 ? Math.floor(remaining * 0.12) :
              Math.floor(remaining * 0.04);
          hourlySteps[hourKey] = Math.min(chunk, remaining);
          remaining -= hourlySteps[hourKey];
        }
        // Distribute remaining
        if (remaining > 0) hourlySteps['12'] = (hourlySteps['12'] || 0) + remaining;

        await StepRecord.create({
          userId: user._id,
          companyId: user.companyId,
          date: dateStr,
          steps: baseSteps,
          distance: Math.round(baseSteps * 0.762),
          calories: Math.round(baseSteps * 0.04 * 100) / 100,
          hourlySteps,
        });
        stepRecordCount++;
      }
    }

    console.log(`   Created ${stepRecordCount} step records`);

    // ===================================================
    // CONTESTS
    // ===================================================
    console.log('\n🏆 Creating contests...');

    // Active contest for group 1
    const contestStart1 = new Date(today);
    contestStart1.setDate(contestStart1.getDate() - 3);
    const contestEnd1 = new Date(today);
    contestEnd1.setDate(contestEnd1.getDate() + 4);

    const contest1 = await Contest.create({
      name: 'Thử thách 10,000 bước',
      description: 'Ai đi được nhiều bước nhất trong tuần?',
      groupId: group1._id,
      companyId: company1._id,
      createdBy: admin1._id,
      startDate: contestStart1,
      endDate: contestEnd1,
      status: 'active',
      participants: allMembers1,
    });

    // Create leaderboard entries
    for (let i = 0; i < allMembers1.length; i++) {
      const steps = Math.floor(Math.random() * 30000) + 15000; // 15k-45k
      await ContestLeaderboard.create({
        contestId: contest1._id,
        userId: allMembers1[i],
        totalSteps: steps,
        rank: 0, // will be set below
        dailySteps: {
          [new Date(today.getTime() - 3 * 86400000).toISOString().split('T')[0]]: Math.floor(steps * 0.3),
          [new Date(today.getTime() - 2 * 86400000).toISOString().split('T')[0]]: Math.floor(steps * 0.35),
          [new Date(today.getTime() - 1 * 86400000).toISOString().split('T')[0]]: Math.floor(steps * 0.35),
        },
      });
    }

    // Calculate ranks
    const leaderboard1 = await ContestLeaderboard.find({ contestId: contest1._id })
      .sort({ totalSteps: -1 });
    for (let i = 0; i < leaderboard1.length; i++) {
      leaderboard1[i].rank = i + 1;
      await leaderboard1[i].save();
    }

    // Upcoming contest for group 2
    const contestStart2 = new Date(today);
    contestStart2.setDate(contestStart2.getDate() + 2);
    const contestEnd2 = new Date(today);
    contestEnd2.setDate(contestEnd2.getDate() + 9);

    await Contest.create({
      name: 'Cuộc đua Marketing',
      description: 'Team marketing thử sức!',
      groupId: group2._id,
      companyId: company1._id,
      createdBy: admin1._id,
      startDate: contestStart2,
      endDate: contestEnd2,
      status: 'upcoming',
      participants: marketingMembers,
    });

    // Completed contest for company 2
    const contestStart3 = new Date(today);
    contestStart3.setDate(contestStart3.getDate() - 10);
    const contestEnd3 = new Date(today);
    contestEnd3.setDate(contestEnd3.getDate() - 3);

    const contest3 = await Contest.create({
      name: 'Tuần lễ sức khỏe',
      description: 'Đi bộ cùng Healthy Squad',
      groupId: group3._id,
      companyId: company2._id,
      createdBy: admin2._id,
      startDate: contestStart3,
      endDate: contestEnd3,
      status: 'completed',
      participants: allMembers2,
    });

    for (let i = 0; i < allMembers2.length; i++) {
      const steps = Math.floor(Math.random() * 50000) + 20000;
      await ContestLeaderboard.create({
        contestId: contest3._id,
        userId: allMembers2[i],
        totalSteps: steps,
        rank: i + 1,
        dailySteps: {},
      });
    }

    console.log('   Contest 1: Thử thách 10,000 bước (active)');
    console.log('   Contest 2: Cuộc đua Marketing (upcoming)');
    console.log('   Contest 3: Tuần lễ sức khỏe (completed)');

    // ===================================================
    // SUMMARY
    // ===================================================
    console.log('\n');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🎉 Demo data seeded successfully!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('');
    console.log('📋 COMPANY 1: Công ty ABC');
    console.log(`   Code: ${company1.code}`);
    console.log(`   Admin: admin@abc.vn / ${PASSWORD}`);
    console.log(`   Members: hoa@abc.vn, tuan@abc.vn, lan@abc.vn, hung@abc.vn, ha@abc.vn`);
    console.log(`   Groups: Phòng Kỹ thuật, Team Marketing`);
    console.log('');
    console.log('📋 COMPANY 2: Công ty XYZ');
    console.log(`   Code: ${company2.code}`);
    console.log(`   Admin: admin@xyz.vn / ${PASSWORD}`);
    console.log(`   Members: mai@xyz.vn, long@xyz.vn, thu@xyz.vn`);
    console.log(`   Groups: Healthy Squad`);
    console.log('');
    console.log(`   All member passwords: ${PASSWORD}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('');

    process.exit(0);
  } catch (err) {
    console.error('❌ Error seeding demo data:', err);
    process.exit(1);
  }
}

seedDemoData();
