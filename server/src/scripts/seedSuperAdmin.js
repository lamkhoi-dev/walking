/**
 * Seed Super Admin script
 * Run once: node src/scripts/seedSuperAdmin.js
 */

const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const User = require('../models/User');
const config = require('../config/env');

async function seedSuperAdmin() {
  try {
    await mongoose.connect(config.mongodbUri);
    console.log('✅ Connected to MongoDB');

    // Check if super_admin already exists
    const existing = await User.findOne({ role: 'super_admin' });
    if (existing) {
      console.log('⚠️  Super Admin already exists:');
      console.log(`   Email: ${existing.email}`);
      console.log('   Password: (unchanged)');
      process.exit(0);
    }

    const superAdmin = new User({
      email: config.superAdmin.email,
      password: config.superAdmin.password,
      fullName: 'Super Admin',
      role: 'super_admin',
      isActive: true,
    });

    await superAdmin.save();

    console.log('');
    console.log('🎉 Super Admin created successfully!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`   Email:    ${config.superAdmin.email}`);
    console.log(`   Password: ${config.superAdmin.password}`);
    console.log(`   Role:     super_admin`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('');

    process.exit(0);
  } catch (err) {
    console.error('❌ Error seeding super admin:', err.message);
    process.exit(1);
  }
}

seedSuperAdmin();
