const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const env = require('./config/env');
const errorHandler = require('./middleware/errorHandler');
const { globalLimiter } = require('./middleware/rateLimiter');

const app = express();

// ===== TRUST PROXY (Railway/reverse proxy) =====
app.set('trust proxy', 1);

// ===== SECURITY MIDDLEWARE =====
app.use(helmet());

// ===== CORS =====
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, curl, etc.)
    if (!origin) return callback(null, true);
    const allowedOrigins = [
      env.clientUrl,
      env.appUrl,
      'http://localhost:3000',
      'http://localhost:5173',
      'https://walktogether-api.onrender.com',
    ];
    if (allowedOrigins.includes(origin) || origin.endsWith('.onrender.com')) {
      return callback(null, true);
    }
    callback(null, true); // Allow all for now (mobile app)
  },
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
app.use('/api/v1/settings', require('./routes/settings.routes'));
app.use('/api/v1/posts', require('./routes/post.routes'));

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
