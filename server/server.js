const http = require('http');
const env = require('./src/config/env');
const connectDB = require('./src/config/db');
const { initSocket } = require('./src/config/socket');
const app = require('./src/app');
const logger = require('./src/utils/logger');
const startContestChecker = require('./src/jobs/contestChecker');
const startStepAggregation = require('./src/jobs/stepAggregation');

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
initSocket(server, {
  corsOrigins: [env.clientUrl, env.appUrl, 'http://localhost:3000', 'http://localhost:5173'],
});

// Connect to MongoDB then start server
const startServer = async () => {
  try {
    await connectDB(env.mongodbUri);
  } catch (error) {
    logger.error('❌ MongoDB connection failed:', error.message);
    if (env.nodeEnv !== 'development') {
      process.exit(1);
    }
    logger.warn('⚠️ Running in dev mode without MongoDB - some features will not work');
  }

  server.listen(env.port, () => {
    logger.info(`🚀 Server running on port ${env.port} [${env.nodeEnv}]`);
    logger.info(`📋 Health check: http://localhost:${env.port}/api/v1/health`);

    // Start cron jobs
    startContestChecker();
    startStepAggregation();
  });
};

// Graceful shutdown
const gracefulShutdown = (signal) => {
  logger.info(`${signal} received. Shutting down gracefully...`);
  server.close(async () => {
    try {
      const mongoose = require('mongoose');
      await mongoose.disconnect();
      logger.info('MongoDB disconnected');
    } catch (err) {
      logger.error('MongoDB disconnect error:', err.message);
    }
    logger.info('Server closed');
    process.exit(0);
  });

  // Force close after 10s
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle unhandled rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  gracefulShutdown('UNHANDLED_REJECTION');
});

startServer();
