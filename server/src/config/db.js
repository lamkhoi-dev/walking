const mongoose = require('mongoose');
const logger = require('../utils/logger');

const MAX_RETRIES = 3;
const RETRY_DELAY = 5000; // 5 seconds

const connectDB = async (uri) => {
  let retries = 0;

  while (retries < MAX_RETRIES) {
    try {
      await mongoose.connect(uri, {
        // Mongoose 8 defaults are good, but explicit for clarity
        serverSelectionTimeoutMS: 10000,
        socketTimeoutMS: 45000,
      });
      logger.info('✅ MongoDB connected successfully');
      
      mongoose.connection.on('error', (err) => {
        logger.error('MongoDB connection error:', err);
      });

      mongoose.connection.on('disconnected', () => {
        logger.warn('MongoDB disconnected. Attempting to reconnect...');
      });

      return;
    } catch (error) {
      retries += 1;
      logger.error(`❌ MongoDB connection attempt ${retries}/${MAX_RETRIES} failed: ${error.message}`);
      
      if (retries >= MAX_RETRIES) {
        logger.error('❌ Max retries reached. Could not connect to MongoDB.');
        throw new Error('MongoDB connection failed after max retries');
      }

      logger.info(`⏱️ Retrying in ${RETRY_DELAY / 1000}s...`);
      await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY));
    }
  }
};

module.exports = connectDB;
