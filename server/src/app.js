const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const env = require('./config/env');
const errorHandler = require('./middleware/errorHandler');
const { globalLimiter } = require('./middleware/rateLimiter');

const app = express();

// ===== SECURITY MIDDLEWARE =====
app.use(helmet());

// ===== CORS =====
app.use(cors({
  origin: [env.clientUrl, env.appUrl, 'http://localhost:3000', 'http://localhost:5173'],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

// ===== BODY PARSERS =====
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ===== LOGGING =====
if (env.nodeEnv === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// ===== GLOBAL RATE LIMITER =====
app.use(globalLimiter);

// ===== HEALTH CHECK =====
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'WalkTogether API is running',
    timestamp: new Date().toISOString(),
    environment: env.nodeEnv,
  });
});

// ===== API ROUTES =====
app.use('/api/v1/auth', require('./routes/auth.routes'));
app.use('/api/v1/admin', require('./routes/admin.routes'));
app.use('/api/v1/companies', require('./routes/company.routes'));
app.use('/api/v1/groups', require('./routes/group.routes'));
app.use('/api/v1/chat', require('./routes/chat.routes'));
app.use('/api/v1/contests', require('./routes/contest.routes'));
app.use('/api/v1/steps', require('./routes/step.routes'));

// ===== 404 HANDLER =====
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`,
  });
});

// ===== GLOBAL ERROR HANDLER =====
app.use(errorHandler);

module.exports = app;
