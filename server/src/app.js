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
app.use('/api/v1/reports', require('./routes/report.routes'));
app.use('/api/v1/friends', require('./routes/friend.routes'));

// ===== DELETE ACCOUNT PAGE (required by Google Play / App Store) =====
app.get('/delete-account', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Xóa tài khoản Runly</title>
  <style>
    body { font-family: -apple-system, sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; color: #333; }
    h1 { color: #e53e3e; }
    .step { background: #f7fafc; border-left: 4px solid #4299e1; padding: 12px 16px; margin: 12px 0; border-radius: 4px; }
    .note { background: #fff5f5; border-left: 4px solid #e53e3e; padding: 12px 16px; margin: 16px 0; border-radius: 4px; }
    a { color: #4299e1; }
  </style>
</head>
<body>
  <h1>Xóa tài khoản Runly</h1>
  <p>Để yêu cầu xóa tài khoản và toàn bộ dữ liệu của bạn, thực hiện các bước sau:</p>

  <div class="step"><strong>Bước 1:</strong> Mở app Runly trên điện thoại</div>
  <div class="step"><strong>Bước 2:</strong> Vào <strong>Cài đặt</strong> (Settings)</div>
  <div class="step"><strong>Bước 3:</strong> Cuộn xuống cuối trang, chọn <strong>"Xóa tài khoản"</strong></div>
  <div class="step"><strong>Bước 4:</strong> Nhập mật khẩu để xác nhận → bấm <strong>Xác nhận xóa</strong></div>

  <div class="note">
    <strong>Lưu ý:</strong> Khi xóa tài khoản, toàn bộ dữ liệu bao gồm hồ sơ, bài viết, tin nhắn và lịch sử hoạt động sẽ bị xóa vĩnh viễn và không thể khôi phục.
  </div>

  <p>Nếu bạn cần hỗ trợ thêm, liên hệ: <a href="mailto:walkingapp51@gmail.com">walkingapp51@gmail.com</a></p>

  <hr>
  <p><strong>Delete Runly Account (English)</strong></p>
  <p>To delete your account and all associated data:</p>
  <ol>
    <li>Open the Runly app</li>
    <li>Go to <strong>Settings</strong></li>
    <li>Scroll to the bottom and tap <strong>"Delete Account"</strong></li>
    <li>Enter your password to confirm</li>
  </ol>
  <p>All data including profile, posts, messages, and activity history will be permanently deleted.</p>
  <p>Contact: <a href="mailto:walkingapp51@gmail.com">walkingapp51@gmail.com</a></p>
</body>
</html>`);
});

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
