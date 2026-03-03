const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Conversation = require('../models/Conversation');
const env = require('./env');
const chatHandler = require('../socket/chatHandler');
const stepHandler = require('../socket/stepHandler');
const leaderboardHandler = require('../socket/leaderboardHandler');
const logger = require('../utils/logger');

let io;

/**
 * Initialize Socket.IO server with JWT auth and chat handlers
 * @param {import('http').Server} httpServer
 * @param {object} options - CORS options etc
 * @returns {Server}
 */
const initSocket = (httpServer, options = {}) => {
  io = new Server(httpServer, {
    cors: {
      origin: options.corsOrigins || ['http://localhost:5173', 'http://localhost:3000'],
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
    transports: ['websocket', 'polling'],
  });

  // ===== AUTH MIDDLEWARE =====
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        return next(new Error('Token không tồn tại'));
      }

      const decoded = jwt.verify(token, env.jwt.secret);
      const user = await User.findById(decoded.id).select('fullName avatar companyId role');

      if (!user) {
        return next(new Error('Người dùng không tồn tại'));
      }

      // Attach user info to socket
      socket.userId = String(user._id);
      socket.fullName = user.fullName;
      socket.companyId = String(user.companyId);
      socket.userRole = user.role;

      next();
    } catch (err) {
      logger.error(`Socket auth error: ${err.message}`);
      next(new Error('Token không hợp lệ'));
    }
  });

  // ===== CONNECTION HANDLER =====
  io.on('connection', async (socket) => {
    const userId = socket.userId;
    logger.info(`🔌 Socket connected: ${socket.id} (user: ${userId})`);

    // Join personal room for direct notifications
    socket.join(`user:${userId}`);

    // Auto-join all conversation rooms this user belongs to
    try {
      const conversations = await Conversation.find({
        participants: userId,
        isActive: true,
      }).select('_id');

      conversations.forEach((conv) => {
        socket.join(`conversation:${conv._id}`);
      });

      logger.debug(`User ${userId} auto-joined ${conversations.length} conversation rooms`);
    } catch (err) {
      logger.error(`Auto-join rooms error: ${err.message}`);
    }

    // Broadcast online status
    socket.to(`company:${socket.companyId}`).emit('user:online', {
      userId,
      fullName: socket.fullName,
    });

    // Join company room
    socket.join(`company:${socket.companyId}`);

    // Register chat event handlers
    chatHandler(io, socket);

    // Register step event handlers
    stepHandler(io, socket);

    // Register leaderboard event handlers
    leaderboardHandler(io, socket);

    // ===== DISCONNECT =====
    socket.on('disconnect', async (reason) => {
      logger.info(`🔌 Socket disconnected: ${socket.id} (user: ${userId}) - ${reason}`);

      // Broadcast offline status
      socket.to(`company:${socket.companyId}`).emit('user:offline', {
        userId,
        fullName: socket.fullName,
      });

      // Update last online
      try {
        await User.findByIdAndUpdate(userId, { lastOnline: new Date() });
      } catch (err) {
        logger.error(`Update lastOnline error: ${err.message}`);
      }
    });

    socket.on('error', (error) => {
      logger.error(`Socket error: ${socket.id} - ${error.message}`);
    });
  });

  logger.info('✅ Socket.IO initialized with auth + chat handlers');
  return io;
};

/**
 * Get the Socket.IO instance
 * @returns {Server}
 */
const getIO = () => {
  if (!io) {
    throw new Error('Socket.IO not initialized. Call initSocket first.');
  }
  return io;
};

module.exports = { initSocket, getIO };
