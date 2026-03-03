# 🗺️ WalkTogether - Phase 1 Implementation Plan

> **Version**: 1.0  
> **Created**: 2026-03-02  
> **Reference**: PROJECT_DOCUMENT.md, MASTER_PLAN.md  
> **Scope**: Phase 1 (LOCKED IN) → Demo Ready  
> **Plan tổng**: Xem [MASTER_PLAN.md](MASTER_PLAN.md) cho tất cả phases

---

## 📋 Mục lục

1. [Tổng quan kế hoạch](#1-tổng-quan-kế-hoạch)
2. [Sprint Breakdown](#2-sprint-breakdown)
3. [Sprint 0 — Project Setup](#3-sprint-0--project-setup)
4. [Sprint 1 — Auth & Company Registration](#4-sprint-1--auth--company-registration)
5. [Sprint 2 — Super Admin Web Portal](#5-sprint-2--super-admin-web-portal)
6. [Sprint 3 — Groups & Members](#6-sprint-3--groups--members)
7. [Sprint 4 — Chat System](#7-sprint-4--chat-system)
8. [Sprint 5 — Step Counter & Sync](#8-sprint-5--step-counter--sync)
9. [Sprint 6 — Contests & Leaderboard](#9-sprint-6--contests--leaderboard)
10. [Sprint 7 — Integration, Polish & Demo](#10-sprint-7--integration-polish--demo)
11. [Task Dependencies](#11-task-dependencies)
12. [Testing Strategy](#12-testing-strategy)
13. [Demo Checklist](#13-demo-checklist)

---

## 1. Tổng quan kế hoạch

### 1.1 Approach

Mỗi sprint tập trung vào **1 feature module** và implement theo thứ tự:

```
Backend API → Test API (Postman) → Flutter UI → Integration → Verify
```

Mỗi task sẽ được chia nhỏ đến mức **1 task = 1 file hoặc 1 function rõ ràng**, dễ implement và verify.

### 1.2 Sprint Overview

| Sprint | Tên | Mô tả | Dependencies |
|---|---|---|---|
| **Sprint 0** | Project Setup | Init projects, config, deploy pipeline | None |
| **Sprint 1** | Auth & Company | Đăng ký, đăng nhập, company registration | Sprint 0 |
| **Sprint 2** | Super Admin Portal | Web portal phê duyệt công ty | Sprint 1 |
| **Sprint 3** | Groups & Members | Tạo nhóm, quản lý thành viên, QR code | Sprint 1 |
| **Sprint 4** | Chat System | Chat nhóm, chat 1v1, gửi hình | Sprint 3 |
| **Sprint 5** | Step Counter | Đếm bước, foreground service, sync | Sprint 1 |
| **Sprint 6** | Contests & Leaderboard | Cuộc thi, bảng xếp hạng | Sprint 3 + 5 |
| **Sprint 7** | Integration & Polish | Kết nối, sửa lỗi, chuẩn bị demo | All |

### 1.3 Parallel Work

```
Sprint 0 ──→ Sprint 1 ──→ Sprint 2
                  │
                  ├──→ Sprint 3 ──→ Sprint 4
                  │         │
                  └──→ Sprint 5    │
                            │      │
                            └──────┴──→ Sprint 6 ──→ Sprint 7
```

> Sprint 3 (Groups) và Sprint 5 (Step Counter) có thể chạy **song song** sau Sprint 1.

---

## 2. Sprint Breakdown

---

## 3. Sprint 0 — Project Setup

> **Mục tiêu**: Khởi tạo toàn bộ project, config environment, deploy thử lên Render.

### 3.1 Backend Setup

#### Task 0.1: Init Node.js Project
```
Tạo folder: server/
├── npm init -y
├── Cài dependencies:
│   ├── express, cors, helmet, morgan
│   ├── mongoose
│   ├── jsonwebtoken, bcryptjs
│   ├── socket.io
│   ├── multer, cloudinary
│   ├── joi
│   ├── express-rate-limit
│   ├── node-cron
│   ├── winston
│   ├── dotenv
│   └── nodemon (dev)
└── Tạo .env.example
```

**File cần tạo:**
- `server/package.json`
- `server/.env.example`
- `server/.gitignore`

#### Task 0.2: Config Files
```
Tạo các config files:
├── src/config/db.js            → MongoDB connection (mongoose.connect)
├── src/config/env.js           → Load & validate env variables
├── src/config/cloudinary.js    → Cloudinary SDK config
└── src/config/socket.js        → Socket.IO initialization
```

**Chi tiết `db.js`:**
```javascript
// - mongoose.connect(MONGODB_URI)
// - Log: "MongoDB connected" hoặc error
// - Retry logic: 3 lần, mỗi lần cách 5s
```

**Chi tiết `env.js`:**
```javascript
// Required env vars:
// PORT, MONGODB_URI, JWT_SECRET, JWT_REFRESH_SECRET,
// JWT_EXPIRES_IN (7d), JWT_REFRESH_EXPIRES_IN (30d),
// CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET,
// CLIENT_URL (CORS origin)
```

#### Task 0.3: Express App Setup
```
Tạo files:
├── src/app.js                  → Express app configuration
├── server.js                   → Entry point (app.listen + socket.io attach)
└── src/middleware/errorHandler.js → Global error handler
```

**Chi tiết `app.js`:**
```javascript
// 1. express()
// 2. Middleware: cors, helmet, morgan, express.json, express.urlencoded
// 3. Rate limiter (global)
// 4. Routes: /api/v1/health → { status: 'ok' }
// 5. Error handler middleware (cuối cùng)
```

**Chi tiết `server.js`:**
```javascript
// 1. Load env
// 2. Connect MongoDB
// 3. Create HTTP server from Express app
// 4. Attach Socket.IO to HTTP server
// 5. Listen on PORT
// 6. Log: "Server running on port {PORT}"
```

#### Task 0.4: Utility Files
```
Tạo files:
├── src/utils/response.js       → success() / error() response helpers
├── src/utils/constants.js      → ROLES, COMPANY_STATUS, MESSAGE_TYPES enums
└── src/utils/generateCompanyCode.js → Generate 6-char company code
```

**Chi tiết `response.js`:**
```javascript
exports.success = (res, statusCode, message, data, pagination) => {
  res.status(statusCode).json({ success: true, message, data, pagination });
};

exports.error = (res, statusCode, message, errorCode, details) => {
  res.status(statusCode).json({ success: false, message, error: { code: errorCode, details } });
};
```

**Chi tiết `constants.js`:**
```javascript
exports.ROLES = { SUPER_ADMIN: 'super_admin', COMPANY_ADMIN: 'company_admin', MEMBER: 'member' };
exports.COMPANY_STATUS = { PENDING: 'pending', APPROVED: 'approved', REJECTED: 'rejected', SUSPENDED: 'suspended' };
exports.MESSAGE_TYPES = { TEXT: 'text', IMAGE: 'image', SYSTEM: 'system' };
exports.CONVERSATION_TYPES = { GROUP: 'group', DIRECT: 'direct' };
exports.CONTEST_STATUS = { UPCOMING: 'upcoming', ACTIVE: 'active', COMPLETED: 'completed', CANCELLED: 'cancelled' };
```

#### Task 0.5: Deploy Backend to Render
```
1. Push code lên GitHub
2. Tạo Web Service trên Render:
   - Runtime: Node
   - Build: npm install
   - Start: node server.js
   - Env vars: set từ .env.example
3. Set up MongoDB Atlas (M0 Free):
   - Tạo cluster → Get connection string
   - Whitelist Render IPs (hoặc 0.0.0.0/0 cho dev)
4. Set up Cloudinary account → Get credentials
5. Verify: GET /api/v1/health → 200 OK  
```

### 3.2 Flutter App Setup

#### Task 0.6: Init Flutter Project
```
flutter create --org com.walktogether walktogether_app
cd walktogether_app

Cài dependencies (pubspec.yaml):
dependencies:
  flutter_bloc: ^8.x
  go_router: ^14.x
  dio: ^5.x
  socket_io_client: ^2.x
  shared_preferences: ^2.x
  hive: ^2.x
  hive_flutter: ^1.x
  pedometer_2: ^latest
  flutter_local_notifications: ^latest
  flutter_foreground_task: ^latest
  image_picker: ^1.x
  cached_network_image: ^3.x
  qr_flutter: ^4.x
  mobile_scanner: ^5.x
  intl: ^0.19.x
  equatable: ^2.x
  json_annotation: ^4.x
  freezed_annotation: ^2.x

dev_dependencies:
  build_runner: ^2.x
  json_serializable: ^6.x
  freezed: ^2.x
```

#### Task 0.7: Flutter Core Structure
```
Tạo folder structure:
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      → Theme colors
│   │   ├── app_text_styles.dart  → Text styles
│   │   ├── api_endpoints.dart    → Base URL + endpoints
│   │   └── app_constants.dart    → Timeouts, limits
│   ├── network/
│   │   ├── dio_client.dart       → Dio instance + interceptors
│   │   └── api_exceptions.dart   → Custom exception classes
│   ├── services/
│   │   └── storage_service.dart  → SharedPreferences wrapper
│   ├── utils/
│   │   ├── validators.dart       → Form validators
│   │   └── helpers.dart          → Format number, date etc
│   └── router/
│       └── app_router.dart       → GoRouter config
└── main.dart                     → App entry point
```

**Chi tiết `dio_client.dart`:**
```dart
// 1. Base URL = API_BASE_URL
// 2. connectTimeout = 90s (Render cold start)
// 3. receiveTimeout = 90s
// 4. Interceptors:
//    a. AuthInterceptor: thêm Bearer token vào header
//    b. RetryInterceptor: retry 3 lần (5s, 15s, 30s)
//    c. LogInterceptor: log request/response (debug only)
//    d. ErrorInterceptor: parse error response → throw custom exceptions
// 5. Token refresh logic: nếu 401 → gọi /auth/refresh-token → retry
```

**Chi tiết `app_router.dart`:**
```dart
// Routes:
// /welcome          → WelcomePage (login/register options)
// /login            → LoginPage
// /register         → RegisterPage
// /pending-approval → PendingApprovalPage
// /rejected         → RejectedPage
// /suspended        → SuspendedPage
// /home             → HomePage (shell route with bottom nav)
//   /home/groups    → GroupsPage
//   /home/chat      → ChatListPage
//   /home/activity  → ActivityPage (step counter)
//   /home/profile   → ProfilePage
// /group/:id        → GroupDetailPage
// /chat/:id         → ChatPage
// /contest/:id      → ContestDetailPage
//
// Auth guard:
// - Redirect to /welcome nếu chưa login
// - Redirect to /pending-approval nếu company pending
// - Redirect to /rejected nếu company rejected
// - Redirect to /suspended nếu company suspended
```

#### Task 0.8: Flutter Theme & Shared Widgets
```
Tạo files:
├── lib/core/theme/app_theme.dart        → ThemeData (light)
├── lib/shared/widgets/custom_button.dart → Primary/Secondary buttons
├── lib/shared/widgets/custom_text_field.dart → Styled text input
├── lib/shared/widgets/loading_widget.dart    → Loading spinner
├── lib/shared/widgets/error_widget.dart      → Error display
└── lib/shared/widgets/avatar_widget.dart     → Circular avatar
```

### 3.3 Web Portal Setup

#### Task 0.9: Init React Project
```
npm create vite@latest web-admin -- --template react
cd web-admin

Cài dependencies:
├── axios
├── @tanstack/react-query
├── react-router-dom
├── antd (hoặc @mui/material)
└── dayjs
```

#### Task 0.10: Web Core Structure
```
Tạo files:
├── src/api/axiosClient.js       → Axios instance + interceptors
├── src/context/AuthContext.jsx   → Auth state management
├── src/App.jsx                  → Router setup
└── src/main.jsx                 → Entry point
```

---

## 4. Sprint 1 — Auth & Company Registration

> **Mục tiêu**: User có thể đăng ký, đăng nhập. Company có thể đăng ký qua web. Login flow xử lý đúng company status.

### 4.1 Backend — Models

#### Task 1.1: User Model
```
File: src/models/User.js

Schema fields:
- email: String, unique, sparse, trim, lowercase
- phone: String, unique, sparse, trim
- password: String, required, select: false (ẩn mặc định)
- fullName: String, required, trim
- avatar: String, default: null
- role: String, enum [super_admin, company_admin, member], required
- companyId: ObjectId, ref: 'Company'
- companyCode: String
- isActive: Boolean, default: true
- deviceToken: String
- lastOnline: Date

Options: timestamps: true

Pre-save hook: hash password bằng bcrypt (salt: 12)
Methods: comparePassword(candidatePassword) → bcrypt.compare

Indexes:
- { email: 1 } unique sparse
- { phone: 1 } unique sparse
- { companyId: 1 }
```

#### Task 1.2: Company Model
```
File: src/models/Company.js

Schema fields:
- name: String, required, trim
- email: String, required, unique, trim, lowercase
- phone: String, trim
- address: String
- description: String
- logo: String
- code: String, unique, sparse (chỉ generate khi approved)
- status: String, enum [pending, approved, rejected, suspended], default: 'pending'
- adminId: ObjectId, ref: 'User'
- totalMembers: Number, default: 0

Options: timestamps: true

Indexes:
- { code: 1 } unique sparse
- { status: 1 }
- { adminId: 1 }
```

### 4.2 Backend — Auth Middleware

#### Task 1.3: Auth Middleware
```
File: src/middleware/auth.js

Function: authenticate(req, res, next)
Logic:
1. Lấy token từ header: Authorization: Bearer <token>
2. Nếu không có → 401 "Token không tồn tại"
3. jwt.verify(token, JWT_SECRET)
4. Nếu expired → 401 "Token hết hạn"
5. Tìm user bằng id decode từ token → select('+companyId')
6. Nếu user không tồn tại hoặc !isActive → 401
7. req.user = user
8. next()
```

#### Task 1.4: Role Middleware
```
File: src/middleware/role.js

Function: authorize(...roles)
→ Return middleware: (req, res, next)
Logic:
1. Check req.user.role có trong roles[]
2. Nếu không → 403 "Bạn không có quyền truy cập"
3. next()

Cách dùng: router.get('/admin/companies', authenticate, authorize('super_admin'), controller)
```

#### Task 1.5: Company Status Middleware
```
File: src/middleware/companyStatus.js

Function: requireApprovedCompany(req, res, next)
Logic:
1. Nếu req.user.role === 'super_admin' → next() (skip check)
2. Tìm company bằng req.user.companyId
3. Nếu company.status === 'approved' → next()
4. Nếu 'pending' → 403 "Công ty đang chờ phê duyệt"
5. Nếu 'rejected' → 403 "Công ty đã bị từ chối"
6. Nếu 'suspended' → 403 "Công ty đã bị tạm ngưng"

Áp dụng: Tất cả routes TRỪ /auth/* và GET /company/status
```

### 4.3 Backend — Auth Controller & Routes

#### Task 1.6: Auth Service
```
File: src/services/auth.service.js

Functions:

1. registerUser({ email, phone, password, fullName, companyCode })
   - Validate: email hoặc phone phải có ít nhất 1
   - Tìm company bằng companyCode → check status === 'approved'
   - Check email/phone chưa tồn tại
   - Tạo user với role: 'member', companyId: company._id
   - Cập nhật company.totalMembers += 1
   - Generate tokens
   - Return { user, accessToken, refreshToken }

2. registerCompany({ companyName, email, phone, address, description, adminEmail, adminPassword, adminFullName })
   - Check email chưa tồn tại (cả company và user)
   - Tạo company (status: 'pending', code: null)
   - Tạo user (role: 'company_admin', companyId)
   - Cập nhật company.adminId = user._id
   - Return { company, user }

3. login({ identifier, password })
   - Tìm user bằng email HOẶC phone, select('+password')
   - So sánh password
   - Nếu role === 'company_admin' hoặc 'member':
     → Populate company { _id, name, status, code }
   - Generate tokens
   - Update lastOnline
   - Return { user, company, accessToken, refreshToken }

4. refreshToken({ refreshToken })
   - Verify refresh token
   - Tìm user
   - Generate new access token
   - Return { accessToken }

5. generateTokens(userId)
   - accessToken = jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: '7d' })
   - refreshToken = jwt.sign({ id: userId }, JWT_REFRESH_SECRET, { expiresIn: '30d' })
   - Return { accessToken, refreshToken }
```

#### Task 1.7: Auth Controller
```
File: src/controllers/auth.controller.js

Functions (thin layer, gọi service):
- register(req, res)      → authService.registerUser
- registerCompany(req, res) → authService.registerCompany
- login(req, res)          → authService.login
- refreshToken(req, res)   → authService.refreshToken
- logout(req, res)         → Response success (client xoá token)
- getMe(req, res)          → Return req.user + company info
```

#### Task 1.8: Auth Validation
```
File: src/validators/auth.validator.js (dùng Joi)

Schemas:
1. registerSchema:
   - email: Joi.string().email() (optional nếu có phone)
   - phone: Joi.string().pattern(/^[0-9]{10,11}$/) (optional nếu có email)
   - password: Joi.string().min(6).required()
   - fullName: Joi.string().min(2).max(50).required()
   - companyCode: Joi.string().length(6).required()
   - .or('email', 'phone') → ít nhất 1 trong 2

2. registerCompanySchema:
   - companyName: required
   - email: required, email format
   - adminEmail: required, email format
   - adminPassword: required, min 6
   - adminFullName: required

3. loginSchema:
   - identifier: Joi.string().required() (email hoặc phone)
   - password: Joi.string().required()
```

#### Task 1.9: Auth Routes
```
File: src/routes/auth.routes.js

POST /register          → validate(registerSchema) → authController.register
POST /register-company  → validate(registerCompanySchema) → authController.registerCompany
POST /login             → validate(loginSchema) → authController.login
POST /refresh-token     → authController.refreshToken
POST /logout            → authenticate → authController.logout
GET  /me                → authenticate → authController.getMe
```

#### Task 1.10: Register Routes in App
```
File: src/app.js

Thêm:
app.use('/api/v1/auth', authRoutes);
```

### 4.4 Backend — Company Status API

#### Task 1.11: Company Controller (Status endpoint)
```
File: src/controllers/company.controller.js

Function: getCompanyStatus(req, res)
Logic:
1. Tìm company bằng req.user.companyId
2. Return { companyId, name, status, code, updatedAt }

File: src/routes/company.routes.js
GET /status → authenticate → companyController.getCompanyStatus
(Không cần requireApprovedCompany cho route này)
```

### 4.5 Flutter — Auth Feature

#### Task 1.12: Auth Data Layer
```
Files:
├── lib/features/auth/data/models/
│   ├── user_model.dart          → UserModel (fromJson, toJson)
│   ├── company_model.dart       → CompanyModel (fromJson, toJson)
│   ├── login_request.dart       → LoginRequest model
│   ├── register_request.dart    → RegisterRequest model
│   └── auth_response.dart       → AuthResponse (user, company, tokens)
└── lib/features/auth/data/repositories/
    └── auth_repository.dart     → API calls: login, register, refreshToken, getMe, getCompanyStatus
```

**Chi tiết `auth_repository.dart`:**
```dart
class AuthRepository {
  final DioClient _dio;
  final StorageService _storage;

  Future<AuthResponse> login(LoginRequest request);
  Future<AuthResponse> register(RegisterRequest request);
  Future<void> logout();
  Future<UserModel> getMe();
  Future<CompanyModel> getCompanyStatus();
  Future<String> refreshToken();

  // Lưu/xoá tokens vào SharedPreferences
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clearTokens();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
}
```

#### Task 1.13: Auth BLoC
```
Files:
├── lib/features/auth/presentation/bloc/
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
```

**Events:**
```dart
abstract class AuthEvent {}
class AuthCheckRequested extends AuthEvent {}      // App start
class AuthLoginRequested extends AuthEvent {
  final String identifier;
  final String password;
}
class AuthRegisterRequested extends AuthEvent {
  final String email;  // or phone
  final String password;
  final String fullName;
  final String companyCode;
}
class AuthLogoutRequested extends AuthEvent {}
class AuthCompanyStatusCheckRequested extends AuthEvent {}  // Poll company status
```

**States:**
```dart
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final CompanyModel? company;
}
class AuthPendingApproval extends AuthState {
  final UserModel user;
  final CompanyModel company;
}
class AuthCompanyRejected extends AuthState {
  final UserModel user;
  final CompanyModel company;
}
class AuthCompanySuspended extends AuthState {
  final UserModel user;
  final CompanyModel company;
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
}
```

**BLoC Logic:**
```dart
// on<AuthLoginRequested>:
// 1. emit AuthLoading
// 2. Gọi authRepository.login()
// 3. Lưu tokens
// 4. Check company.status:
//    - 'approved' → emit AuthAuthenticated
//    - 'pending'  → emit AuthPendingApproval
//    - 'rejected' → emit AuthCompanyRejected
//    - 'suspended'→ emit AuthCompanySuspended
// 5. Catch error → emit AuthError

// on<AuthCompanyStatusCheckRequested>:
// 1. Gọi authRepository.getCompanyStatus()
// 2. Nếu 'approved' → emit AuthAuthenticated
// 3. Nếu khác → giữ nguyên state
```

#### Task 1.14: Auth Pages (UI)
```
Files:
├── lib/features/auth/presentation/pages/
│   ├── welcome_page.dart
│   │   → Logo + App name
│   │   → Nút "Đăng nhập"
│   │   → Nút "Đăng ký User"
│   │   → Text link "Đăng ký Doanh nghiệp" → mở browser web portal
│   │
│   ├── login_page.dart
│   │   → TextField: Email hoặc SĐT
│   │   → TextField: Mật khẩu (obscure)
│   │   → Nút "Đăng nhập"
│   │   → Text link "Chưa có tài khoản? Đăng ký"
│   │   → Loading overlay khi đang login
│   │   → Error snackbar
│   │
│   ├── register_page.dart
│   │   → TextField: Họ tên
│   │   → TextField: Email hoặc SĐT (toggle)
│   │   → TextField: Mật khẩu
│   │   → TextField: Nhập lại mật khẩu
│   │   → TextField: Mã công ty (6 ký tự)
│   │   → Nút "Đăng ký"
│   │   → Info text: "Đăng ký doanh nghiệp? Nhấn vào đây"
│   │
│   ├── pending_approval_page.dart
│   │   → Hourglass icon/animation
│   │   → "Đang chờ phê duyệt"
│   │   → Tên công ty + ngày đăng ký
│   │   → Nút "Kiểm tra lại" → gọi getCompanyStatus
│   │   → Auto-poll mỗi 30s
│   │   → Nút "Đăng xuất"
│   │   → Khi approved → snackbar "Đã duyệt!" → navigate Home
│   │
│   ├── rejected_page.dart
│   │   → Warning icon
│   │   → "Đăng ký bị từ chối"
│   │   → Thông tin liên hệ hỗ trợ
│   │   → Nút "Đăng xuất"
│   │
│   └── suspended_page.dart
│       → Warning icon
│       → "Công ty bị tạm ngưng"
│       → Thông tin liên hệ hỗ trợ
│       → Nút "Đăng xuất"
```

### 4.6 Verify Sprint 1

```
✅ Checklist:
□ POST /auth/register → tạo user member thành công
□ POST /auth/register → fail nếu mã công ty sai hoặc chưa approved
□ POST /auth/register-company → tạo company (pending) + admin user
□ POST /auth/login → trả đúng company.status
□ POST /auth/login → company pending → client nhận đúng status
□ GET /auth/me → trả user info đầy đủ
□ GET /company/status → trả company status
□ POST /auth/refresh-token → trả new access token
□ Flutter: Login thành công → navigate Home
□ Flutter: Login company pending → navigate PendingApprovalScreen
□ Flutter: PendingApproval auto-poll → navigate Home khi approved
□ Flutter: Register thành công → auto login
□ Deploy lên Render → test với timeout 90s
```

---

## 5. Sprint 2 — Super Admin Web Portal

> **Mục tiêu**: Super Admin login web, xem danh sách công ty, phê duyệt/từ chối.

### 5.1 Backend — Admin APIs

#### Task 2.1: Admin Controller
```
File: src/controllers/admin.controller.js

Functions:

1. getCompanies(req, res)
   - Query params: page, limit, status (filter), search (tên)
   - Find companies với filter + pagination
   - Populate adminId (fullName, email)
   - Return list + pagination info

2. getCompanyById(req, res)
   - Tìm company bằng ID
   - Populate adminId + count members
   - Return company detail

3. approveCompany(req, res)
   - Tìm company bằng ID
   - Check status === 'pending'
   - Update status → 'approved'
   - Generate company code bằng generateCompanyCode()
   - Set company.code = generated code
   - Save
   - Return updated company

4. rejectCompany(req, res)
   - Update status → 'rejected'
   - Return updated company

5. suspendCompany(req, res)
   - Update status → 'suspended'
   - Return updated company

6. getStats(req, res)
   - Count: total companies, pending, approved, rejected
   - Count: total users, active users
   - Return stats object
```

#### Task 2.2: Admin Routes
```
File: src/routes/admin.routes.js

Tất cả routes: authenticate + authorize('super_admin')

GET    /companies          → adminController.getCompanies
GET    /companies/:id      → adminController.getCompanyById
PUT    /companies/:id/approve  → adminController.approveCompany
PUT    /companies/:id/reject   → adminController.rejectCompany
PUT    /companies/:id/suspend  → adminController.suspendCompany
GET    /stats               → adminController.getStats
```

#### Task 2.3: Seed Super Admin
```
File: src/scripts/seedSuperAdmin.js

Script chạy 1 lần:
- Tạo user super_admin nếu chưa tồn tại
  - email: "admin@walktogether.com"
  - password: "Admin@2026" (hoặc từ env)
  - role: 'super_admin'
  - fullName: "Super Admin"
- Log credentials ra console

Chạy bằng: node src/scripts/seedSuperAdmin.js
```

### 5.2 Web Portal — Pages

#### Task 2.4: Web Auth (Login)
```
Files:
├── src/pages/LoginPage.jsx
│   → Form: Email + Password
│   → Gọi POST /auth/login
│   → Lưu token vào localStorage
│   → Navigate Dashboard
│   → Error handling

├── src/api/axiosClient.js
│   → baseURL = API_BASE_URL
│   → timeout = 90000 (90s cho Render)
│   → Interceptor: thêm Bearer token
│   → Interceptor: 401 → redirect login
```

#### Task 2.5: Web Dashboard
```
File: src/pages/DashboardPage.jsx

→ Gọi GET /admin/stats
→ Hiển thị cards:
  - Tổng công ty
  - Đang chờ duyệt (highlight nếu > 0)
  - Đã duyệt
  - Bị từ chối
  - Tổng users
→ Quick link: "Xem công ty chờ duyệt"
```

#### Task 2.6: Web Company List
```
File: src/pages/CompanyListPage.jsx

→ Gọi GET /admin/companies?status=&search=&page=&limit=
→ Bảng (Table):
  - Columns: Tên, Email, SĐT, Trạng thái (tag), Ngày đăng ký, Hành động
  - Status tags: pending (vàng), approved (xanh), rejected (đỏ), suspended (xám)
→ Filter dropdown: All / Pending / Approved / Rejected / Suspended
→ Search box: tìm theo tên
→ Pagination
→ Click row → CompanyDetailPage
```

#### Task 2.7: Web Company Detail
```
File: src/pages/CompanyDetailPage.jsx

→ Gọi GET /admin/companies/:id
→ Hiển thị:
  - Thông tin công ty (tên, email, SĐT, địa chỉ, mô tả)
  - Thông tin admin (tên, email)
  - Trạng thái hiện tại
  - Mã công ty (nếu đã approved)
  - Ngày đăng ký, ngày cập nhật
→ Action buttons (tuỳ status):
  - pending → [Phê duyệt] [Từ chối]
  - approved → [Tạm ngưng]
  - rejected → (không có action)
  - suspended → [Khôi phục → approved]
→ Confirm modal trước khi thực hiện action
```

### 5.3 Verify Sprint 2

```
✅ Checklist:
□ Super Admin login web thành công
□ Dashboard hiện đúng stats
□ Company list hiện đúng, filter/search hoạt động
□ Phê duyệt → company status = 'approved' + có company code
□ Từ chối → company status = 'rejected'
□ Tạm ngưng → company status = 'suspended'
□ Sau khi approve → Flutter app company admin login → vào Home
□ Deploy web portal lên Vercel/Render
```

---

## 6. Sprint 3 — Groups & Members

> **Mục tiêu**: Admin tạo nhóm, thêm thành viên, tìm nhóm, scan QR.

### 6.1 Backend — Group APIs

#### Task 3.1: Group Model
```
File: src/models/Group.js  (đã define trong Sprint 0 schema, giờ implement)
```

#### Task 3.2: Group Service
```
File: src/services/group.service.js

Functions:

1. createGroup({ name, description, avatar, memberIds, companyId, createdBy })
   - Validate memberIds thuộc cùng companyId
   - Tạo group, tự thêm createdBy vào members
   - Generate QR data: "walktogether://group/{groupId}"
   - Tạo conversation (type: 'group', groupId)
   - Return group

2. getGroups(userId, companyId)
   - Tìm groups mà user là member (hoặc tất cả nếu admin)
   - Populate members (avatar, fullName)
   - Sort by updatedAt desc

3. getGroupById(groupId)
   - Populate members
   - Return group

4. updateGroup(groupId, updateData)
   - Chỉ cho phép update: name, description, avatar

5. deleteGroup(groupId)
   - Soft delete: isActive = false
   - Cũng soft delete conversation liên quan

6. addMembers(groupId, memberIds)
   - Validate members thuộc cùng company
   - Không thêm trùng
   - Cập nhật totalMembers
   - Gửi system message trong group chat: "X đã được thêm vào nhóm"

7. removeMember(groupId, userId)
   - Xoá userId khỏi members[]
   - Cập nhật totalMembers
   - System message: "X đã rời nhóm"

8. searchGroups(companyId, query)
   - Text search trên name field
   - Chỉ trong phạm vi companyId

9. joinByQR(qrCode, userId)
   - Parse groupId từ QR data
   - Check cùng company
   - Add member
```

#### Task 3.3: Group Controller & Routes
```
File: src/controllers/group.controller.js
File: src/routes/group.routes.js

Tất cả routes: authenticate + requireApprovedCompany

POST   /                → authorize('company_admin') → createGroup
GET    /                → getGroups (user's groups)
GET    /search?q=       → searchGroups
GET    /:id             → getGroupById
PUT    /:id             → authorize('company_admin') → updateGroup
DELETE /:id             → authorize('company_admin') → deleteGroup
POST   /:id/members     → authorize('company_admin') → addMembers
DELETE /:id/members/:userId → authorize('company_admin') → removeMember
POST   /join/:qrCode    → joinByQR
```

#### Task 3.4: Company Members API
```
File: src/controllers/company.controller.js (thêm)

Function: getCompanyMembers(req, res)
- Tìm users thuộc companyId, role !== 'super_admin'
- Select: _id, fullName, email, phone, avatar, role
- Search by fullName (optional query param)
- Pagination

Route: GET /company/members → authenticate + requireApprovedCompany
```

### 6.2 Flutter — Group Feature

#### Task 3.5: Group Data Layer
```
Files:
├── lib/features/group/data/models/
│   ├── group_model.dart         → GroupModel (id, name, description, avatar, members, qrCode, totalMembers)
│   └── member_model.dart        → MemberModel (id, fullName, avatar, role)
└── lib/features/group/data/repositories/
    └── group_repository.dart
        → createGroup, getGroups, getGroupById, updateGroup, deleteGroup
        → addMembers, removeMember, searchGroups, joinByQR
        → getCompanyMembers
```

#### Task 3.6: Group BLoC
```
Files:
├── lib/features/group/presentation/bloc/
│   ├── group_list_bloc.dart      → Load danh sách nhóm
│   ├── group_detail_bloc.dart    → Chi tiết nhóm + members
│   └── group_search_bloc.dart    → Tìm kiếm nhóm
```

#### Task 3.7: Group Pages (UI)
```
Files:
├── lib/features/group/presentation/pages/
│   ├── group_list_page.dart
│   │   → AppBar: "Nhóm" + nút tìm kiếm + nút QR scan
│   │   → ListView: nhóm cards (avatar, tên, số thành viên, last message preview)
│   │   → FAB: "Tạo nhóm" (chỉ hiện cho admin)
│   │   → Empty state nếu chưa có nhóm
│   │
│   ├── group_detail_page.dart
│   │   → Header: avatar nhóm + tên + description
│   │   → Tab bar: [Chat] [Thành viên] [Cuộc thi]
│   │   → Tab Chat → ChatPage (embedded)
│   │   → Tab Thành viên → danh sách + nút thêm (admin)
│   │   → Tab Cuộc thi → ContestListPage (embedded)
│   │   → Nút QR code (hiển thị QR nhóm)
│   │
│   ├── create_group_page.dart
│   │   → TextField: Tên nhóm
│   │   → TextField: Mô tả
│   │   → Avatar picker (camera/gallery)
│   │   → Member selector: searchable list với checkbox
│   │   → Nút "Tạo nhóm"
│   │
│   ├── group_search_page.dart
│   │   → SearchBar (debounce 300ms)
│   │   → Kết quả: group cards
│   │   → Empty state: "Không tìm thấy nhóm"
│   │
│   └── group_qr_page.dart
│       → QR code image (qr_flutter)
│       → Tên nhóm
│       → Nút "Chia sẻ QR" (share image)
│
├── lib/features/group/presentation/widgets/
│   ├── group_card.dart           → Card trong danh sách
│   ├── member_list_tile.dart     → Row thành viên
│   └── member_selector.dart      → Multi-select thành viên
```

### 6.3 Verify Sprint 3

```
✅ Checklist:
□ Admin tạo nhóm thành công (tên, mô tả, chọn members)
□ Danh sách nhóm hiện đúng
□ Chi tiết nhóm: thông tin + danh sách thành viên
□ Thêm/xoá thành viên hoạt động
□ Tìm kiếm nhóm bằng tên
□ QR code hiển thị đúng
□ Scan QR → join nhóm thành công (cùng company)
□ Scan QR → fail nếu khác company
□ Member không thấy nút tạo nhóm
```

---

## 7. Sprint 4 — Chat System

> **Mục tiêu**: Chat nhóm, chat 1v1, gửi text + emoji + hình ảnh, realtime qua WebSocket.

### 7.1 Backend — Chat Models & APIs

#### Task 4.1: Conversation & Message Models
```
Files:
├── src/models/Conversation.js   (implement theo schema đã define)
└── src/models/Message.js        (implement theo schema đã define)
```

#### Task 4.2: Chat Service
```
File: src/services/chat.service.js

Functions:

1. getConversations(userId)
   - Tìm conversations mà user là participant hoặc là member của group
   - Populate lastMessage, participants (avatar, fullName)
   - Sort by lastMessage.createdAt desc (mới nhất lên trên)

2. getOrCreateDirectConversation(userId, otherUserId, companyId)
   - Tìm conversation type='direct' có cả 2 participants
   - Nếu chưa có → tạo mới
   - Return conversation

3. getMessages(conversationId, page, limit)
   - Tìm messages theo conversationId
   - Sort by createdAt desc
   - Pagination (cursor-based hoặc offset)
   - Populate senderId (fullName, avatar)

4. createMessage({ conversationId, senderId, type, content, imageUrl })
   - Tạo message
   - Cập nhật conversation.lastMessage
   - Return message (populated)

5. uploadImage(file)
   - Upload to Cloudinary (folder: 'walktogether/chat')
   - Return URL

6. markAsRead(conversationId, userId)
   - Cập nhật readBy cho messages chưa đọc
```

#### Task 4.3: Chat Controller & Routes
```
File: src/controllers/chat.controller.js
File: src/routes/chat.routes.js

Tất cả: authenticate + requireApprovedCompany

GET    /conversations              → getConversations
POST   /conversations/direct       → getOrCreateDirect, body: { userId }
GET    /conversations/:id/messages → getMessages, query: { page, limit }
POST   /conversations/:id/messages → createMessage (REST fallback)
POST   /conversations/:id/upload   → upload middleware → uploadImage
PUT    /conversations/:id/read     → markAsRead
```

#### Task 4.4: Socket.IO Chat Handler
```
File: src/socket/chatHandler.js

Setup:
- Khi user connect → join rooms cho tất cả conversations user tham gia
- Room name format: "conversation:{conversationId}"

Events:

1. 'chat:join' → { conversationId }
   - socket.join("conversation:{conversationId}")

2. 'chat:leave' → { conversationId }
   - socket.leave("conversation:{conversationId}")

3. 'chat:send_message' → { conversationId, type, content, imageUrl? }
   - Tạo message qua chatService
   - Broadcast 'chat:new_message' → room "conversation:{conversationId}"
     (trừ sender)
   - Emit 'chat:new_message' cho sender (confirm)

4. 'chat:typing' → { conversationId, isTyping }
   - Broadcast 'chat:user_typing' → room (trừ sender)
     payload: { conversationId, userId, fullName, isTyping }

5. 'chat:read' → { conversationId, messageId }
   - Gọi chatService.markAsRead
   - Broadcast 'chat:message_read' → room
```

#### Task 4.5: Socket.IO Main Setup
```
File: src/socket/index.js

1. io = new Server(httpServer, { cors, transports: ['websocket', 'polling'] })
2. Auth middleware: verify JWT từ socket.handshake.auth.token
3. On connection:
   a. Lưu socket.userId
   b. Join room "user:{userId}" (cho notification cá nhân)
   c. Join rooms cho conversations
   d. Broadcast 'user:online' cho contacts
4. On disconnect:
   a. Broadcast 'user:offline'
   b. Update user.lastOnline
5. Register handlers: chatHandler(io, socket)
```

### 7.2 Flutter — Chat Feature

#### Task 4.6: Socket Service
```
File: lib/core/socket/socket_service.dart

Singleton class:
- connect(token) → Socket.IO connect với auth token
  - URL: WSS base URL
  - transports: ['websocket']
  - reconnection: true
  - reconnectionDelay: 5000
  - timeout: 90000 (Render cold start)
- disconnect()
- on(event, callback)
- emit(event, data)
- isConnected getter

Gọi connect() sau khi login thành công.
Gọi disconnect() khi logout.
```

#### Task 4.7: Chat Data Layer
```
Files:
├── lib/features/chat/data/models/
│   ├── conversation_model.dart
│   ├── message_model.dart
│   └── typing_model.dart
└── lib/features/chat/data/repositories/
    └── chat_repository.dart
        → getConversations, getOrCreateDirect
        → getMessages (REST, for history)
        → sendMessage (socket emit)
        → uploadImage (REST)
        → markAsRead (socket emit)
```

#### Task 4.8: Chat BLoC
```
Files:
├── lib/features/chat/presentation/bloc/
│   ├── conversation_list_bloc.dart  → Load conversations, listen socket for new messages
│   ├── chat_bloc.dart               → Load messages, send/receive realtime
│   └── typing_bloc.dart             → Typing indicator
```

**Chat BLoC Logic:**
```dart
// on<ChatLoadMessages>:
// 1. Load từ REST: getMessages(conversationId, page: 1)
// 2. Listen socket 'chat:new_message' → thêm vào list
// 3. Emit socket 'chat:join'

// on<ChatSendMessage>:
// 1. Emit socket 'chat:send_message'
// 2. Optimistic update: thêm message vào list ngay (status: sending)
// 3. Khi nhận confirm → update status: sent

// on<ChatLoadMore>:
// 1. Load REST page tiếp theo
// 2. Prepend vào list (tin cũ lên trên)
```

#### Task 4.9: Chat Pages (UI)
```
Files:
├── lib/features/chat/presentation/pages/
│   ├── chat_list_page.dart
│   │   → AppBar: "Tin nhắn"
│   │   → ListView: conversation tiles
│   │     - Avatar (group avatar hoặc user avatar)
│   │     - Tên (group name hoặc user name)
│   │     - Last message preview (truncate)
│   │     - Thời gian
│   │     - Badge số tin chưa đọc
│   │   → Tap → ChatPage
│   │
│   └── chat_page.dart
│       → AppBar: tên conversation + avatar
│       → Message list (grouped by date):
│         - Sent messages: align right, primary color
│         - Received messages: align left, grey
│         - Image messages: thumbnail (tap to fullscreen)
│         - System messages: center, italic
│         - Time stamp dưới mỗi tin
│       → Typing indicator: "Đang gõ..."
│       → Input bar:
│         - TextField (multi-line, max 5 lines)
│         - Nút attach image (icon camera/gallery)
│         - Nút send (icon)
│       → Scroll to bottom on new message
│       → Load more khi scroll lên (infinite scroll)

├── lib/features/chat/presentation/widgets/
│   ├── conversation_tile.dart
│   ├── message_bubble.dart
│   ├── image_message.dart
│   ├── system_message.dart
│   ├── typing_indicator.dart
│   └── chat_input_bar.dart
```

### 7.3 Verify Sprint 4

```
✅ Checklist:
□ Chat nhóm: gửi text realtime (2+ devices)
□ Chat nhóm: gửi emoji
□ Chat nhóm: gửi hình ảnh (gallery + camera)
□ Chat 1v1: tạo conversation + chat realtime
□ Typing indicator hiển thị đúng
□ Lịch sử tin nhắn load đúng (pagination)
□ Danh sách conversations sắp xếp mới nhất lên trên
□ Last message preview cập nhật
□ Badge tin chưa đọc
□ Reconnect WebSocket sau mất mạng
□ Offline → tin nhắn queue → gửi khi online
```

---

## 8. Sprint 5 — Step Counter & Sync

> **Mục tiêu**: App đếm bước chân (foreground service), hiện notification, sync lên server.

### 8.1 Backend — Step APIs

#### Task 5.1: StepRecord Model
```
File: src/models/StepRecord.js (implement)
```

#### Task 5.2: Step Service
```
File: src/services/step.service.js

Functions:

1. syncSteps(userId, companyId, { date, steps, hourlySteps })
   - Upsert: findOneAndUpdate({ userId, date }, { $set: { steps, hourlySteps, syncedAt } }, { upsert: true })
   - Tính distance = steps * 0.762
   - Tính calories = steps * 0.04
   - Nếu user đang trong contest active → cập nhật contest_leaderboard
   - Return updated record

2. getToday(userId)
   - Tìm record hôm nay
   - Return { steps, distance, calories }

3. getHistory(userId, fromDate, toDate)
   - Tìm records trong range
   - Return array sorted by date

4. getStats(userId)
   - Tính tổng tuần này, tháng này
   - Tính trung bình/ngày
   - Return stats object
```

#### Task 5.3: Step Controller & Routes
```
File: src/controllers/step.controller.js
File: src/routes/step.routes.js

Tất cả: authenticate + requireApprovedCompany

POST /sync              → syncSteps
GET  /today             → getToday
GET  /history?from=&to= → getHistory
GET  /stats             → getStats
```

#### Task 5.4: Step Socket Handler
```
File: src/socket/stepHandler.js

Event: 'steps:sync' → { date, steps, hourlySteps }
- Gọi stepService.syncSteps
- Emit 'steps:synced' → { success, todaySteps }
- Nếu có active contest → emit 'leaderboard:update' cho room contest
```

### 8.2 Flutter — Step Counter Feature

#### Task 5.5: Step Counter Service (Native Integration)
```
File: lib/core/services/step_counter_service.dart

Class: StepCounterService

Logic:
1. Init: request permissions (Activity Recognition)
2. Start foreground service (flutter_foreground_task):
   - Android: TYPE_STEP_COUNTER sensor
   - iOS: CMPedometer
3. baselineSteps: lưu step count lúc 00:00 mỗi ngày
4. todaySteps = currentSensorSteps - baselineSteps
5. Update notification mỗi khi steps thay đổi:
   "WalkTogether - Hôm nay: {steps} bước | {distance}m"
6. Lưu steps vào Hive (offline storage)
7. Handle device reboot: detect bằng step count < baseline → reset
```

#### Task 5.6: Step Sync Service
```
File: lib/core/services/step_sync_service.dart

Class: StepSyncService

Logic:
1. Timer: sync mỗi 30s (foreground) / 5 phút (background)
2. syncToServer():
   - Lấy todaySteps từ StepCounterService
   - Gọi POST /steps/sync HOẶC emit socket 'steps:sync'
   - Nếu offline → lưu vào sync queue (Hive)
3. syncQueue():
   - Khi online → gửi tất cả queued records
   - Xoá khỏi queue khi thành công
4. Retry logic:
   - Timeout: 90s (Render)
   - Retry: 3 lần (5s, 15s, 30s)
```

#### Task 5.7: Step Tracker BLoC
```
Files:
├── lib/features/step_tracker/presentation/bloc/
│   ├── step_tracker_bloc.dart
│   ├── step_tracker_event.dart
│   └── step_tracker_state.dart

States:
- StepTrackerInitial
- StepTrackerRunning { todaySteps, distance, calories }
- StepTrackerError { message }

Events:
- StartTracking
- StopTracking
- StepsUpdated { steps }
- SyncCompleted { serverSteps }
```

#### Task 5.8: Step Tracker Pages (UI)
```
Files:
├── lib/features/step_tracker/presentation/pages/
│   └── activity_page.dart
│       → Circular progress ring (animated)
│         - Center: số bước hiện tại
│         - Ring: % mục tiêu (mặc định 10K)
│       → Stats row: Bước | Khoảng cách | Calories
│       → Trạng thái sync: "Đã đồng bộ" / "Đang đồng bộ..."
│       → Toggle start/stop tracking
│       → Notification permission request

├── lib/features/step_tracker/presentation/widgets/
│   ├── step_progress_ring.dart   → Animated circular indicator
│   ├── step_stat_card.dart       → Stat card (icon, value, label)
│   └── sync_status_widget.dart   → Connection status
```

### 8.3 Verify Sprint 5

```
✅ Checklist:
□ Foreground service start → notification hiện
□ Bước chân đếm chính xác (so sánh với Google Fit)
□ Notification cập nhật số bước realtime
□ Sync lên server thành công
□ Offline → lưu local → sync khi online
□ POST /steps/sync → upsert đúng
□ GET /steps/today → trả đúng
□ GET /steps/history → trả đúng range
□ App restart → tiếp tục đếm (không reset)
□ Device reboot → xử lý đúng (baseline reset)
□ Background sync hoạt động (5 phút)
```

---

## 9. Sprint 6 — Contests & Leaderboard

> **Mục tiêu**: Tạo cuộc thi trong nhóm, đếm bước, bảng xếp hạng realtime.

### 9.1 Backend — Contest APIs

#### Task 6.1: Contest & Leaderboard Models
```
Files:
├── src/models/Contest.js           (implement)
└── src/models/ContestLeaderboard.js (implement)
```

#### Task 6.2: Contest Service
```
File: src/services/contest.service.js

Functions:

1. createContest({ name, description, groupId, companyId, createdBy, startDate, endDate })
   - Check: không có contest active/upcoming khác trong cùng group
   - Validate dates: start >= now, end > start
   - Lấy tất cả members từ group → set participants
   - Tạo contest (status: 'upcoming')
   - Tạo contest_leaderboard records cho mỗi participant (totalSteps: 0)
   - Return contest

2. getContests(companyId, groupId?)
   - Filter theo companyId, optional groupId
   - Sort by startDate desc

3. getContestById(contestId)
   - Populate participants info

4. updateContest(contestId, updateData)
   - Chỉ update nếu status = 'upcoming'
   - Cho phép update: name, description, startDate, endDate

5. cancelContest(contestId)
   - Update status → 'cancelled'

6. getActiveContestByGroup(groupId)
   - Tìm contest với status 'active' trong group

7. getLeaderboard(contestId)
   - Tìm contest_leaderboard records
   - Sort by totalSteps desc
   - Populate user info (fullName, avatar)
   - Tính rank
   - Return sorted array
```

#### Task 6.3: Leaderboard Service
```
File: src/services/leaderboard.service.js

Functions:

1. updateLeaderboard(userId, contestId, date, steps)
   - Tìm leaderboard record cho userId + contestId
   - Cập nhật dailySteps cho date
   - Recalculate totalSteps = sum(dailySteps)
   - Save
   - Recalculate ranks cho contestId
   - Return updated leaderboard

2. recalculateRanks(contestId)
   - Tìm tất cả records cho contestId
   - Sort by totalSteps desc
   - Update rank cho từng record
   - Return sorted leaderboard
```

#### Task 6.4: Contest Cron Jobs
```
File: src/jobs/contestChecker.js

Cron: chạy mỗi phút

Logic:
1. Tìm contests status='upcoming' có startDate <= now
   → Update status = 'active'
   
2. Tìm contests status='active' có endDate <= now
   → Update status = 'completed'
   → Final recalculate ranks

File: src/jobs/stepAggregation.js

Cron: chạy lúc 23:55 mỗi ngày

Logic:
1. Tìm tất cả active contests
2. Cho mỗi contest:
   a. Lấy step_records hôm nay cho mỗi participant
   b. Cập nhật contest_leaderboard
   c. Recalculate ranks
→ Đây là bước "đảm bảo chính xác" ngoài realtime updates
```

#### Task 6.5: Contest Controller & Routes
```
File: src/controllers/contest.controller.js
File: src/routes/contest.routes.js

Tất cả: authenticate + requireApprovedCompany

POST   /                         → authorize('company_admin') → createContest
GET    /                         → getContests
GET    /:id                      → getContestById
PUT    /:id                      → authorize('company_admin') → updateContest
DELETE /:id                      → authorize('company_admin') → cancelContest
GET    /:id/leaderboard          → getLeaderboard
GET    /group/:groupId/active    → getActiveContestByGroup
```

#### Task 6.6: Leaderboard Socket Handler
```
File: src/socket/leaderboardHandler.js

Events:

1. 'leaderboard:subscribe' → { contestId }
   - socket.join("contest:{contestId}")

2. 'leaderboard:unsubscribe' → { contestId }
   - socket.leave("contest:{contestId}")

Khi steps sync (trong stepHandler):
- Nếu user trong active contest:
  → Update leaderboard
  → io.to("contest:{contestId}").emit('leaderboard:update', { contestId, leaderboard })
```

### 9.2 Flutter — Contest Feature

#### Task 6.7: Contest Data Layer
```
Files:
├── lib/features/contest/data/models/
│   ├── contest_model.dart
│   └── leaderboard_entry_model.dart
└── lib/features/contest/data/repositories/
    └── contest_repository.dart
```

#### Task 6.8: Contest BLoC
```
Files:
├── lib/features/contest/presentation/bloc/
│   ├── contest_list_bloc.dart
│   ├── contest_detail_bloc.dart
│   └── leaderboard_bloc.dart    → Listen socket 'leaderboard:update'
```

#### Task 6.9: Contest Pages (UI)
```
Files:
├── lib/features/contest/presentation/pages/
│   ├── contest_list_page.dart
│   │   → Danh sách cuộc thi trong nhóm
│   │   → Cards: tên, status badge, ngày bắt đầu/kết thúc
│   │   → FAB: "Tạo cuộc thi" (admin only)
│   │   → Active contest highlight ở trên cùng
│   │
│   ├── create_contest_page.dart
│   │   → TextField: Tên cuộc thi
│   │   → TextField: Mô tả
│   │   → Date picker: Ngày bắt đầu
│   │   → Date picker: Ngày kết thúc
│   │   → Nút "Tạo cuộc thi"
│   │   → Validation feedback
│   │
│   ├── contest_detail_page.dart
│   │   → Header: tên cuộc thi + status + countdown
│   │   → Thông tin: mô tả, ngày, số participants
│   │   → Leaderboard tab (nhúng)
│   │   → Nút huỷ (admin, nếu upcoming/active)
│   │
│   └── leaderboard_page.dart
│       → Top 3 podium: (vàng, bạc, đồng) với avatar lớn
│       → Danh sách từ rank 4 trở đi
│       → Mỗi row: rank, avatar, tên, tổng bước, bước hôm nay
│       → Highlight row của current user
│       → Auto-update realtime (socket)
│       → Pull-to-refresh

├── lib/features/contest/presentation/widgets/
│   ├── contest_card.dart
│   ├── podium_widget.dart         → Top 3 hiển thị đẹp
│   ├── leaderboard_row.dart
│   └── countdown_widget.dart      → Đếm ngược start/end
```

### 9.3 Verify Sprint 6

```
✅ Checklist:
□ Admin tạo cuộc thi thành công
□ Không tạo được 2 cuộc thi active trong 1 nhóm
□ Cuộc thi auto chuyển upcoming → active khi đến startDate
□ Cuộc thi auto chuyển active → completed khi đến endDate
□ Leaderboard hiển thị đúng ranking
□ Leaderboard cập nhật realtime khi có user sync steps
□ Top 3 highlight đúng
□ Current user highlight
□ Admin huỷ cuộc thi thành công
□ Cron job tổng hợp bước cuối ngày chính xác
```

---

## 10. Sprint 7 — Integration, Polish & Demo

> **Mục tiêu**: Kết nối toàn bộ, sửa bug, polish UI, chuẩn bị demo.

### 10.1 Home Page Integration

#### Task 7.1: Home Page with Bottom Navigation
```
File: lib/features/home/presentation/pages/home_page.dart

Bottom Navigation Tabs:
1. 🏠 Home / Activity → ActivityPage (step counter + daily summary)
2. 👥 Nhóm → GroupListPage
3. 💬 Chat → ChatListPage
4. 👤 Profile → ProfilePage (basic)

Logic:
- Khi app start sau login:
  1. Init step counter service
  2. Connect WebSocket
  3. Load groups, conversations
  4. Navigate to Home tab
```

#### Task 7.2: Basic Profile Page
```
File: lib/features/profile/presentation/pages/profile_page.dart

→ Avatar + Tên + Email/SĐT
→ Thông tin công ty (tên, mã công ty cho admin)
→ Nút "Đăng xuất"
→ App version

(Phase 2 sẽ mở rộng: edit profile, stats, history)
```

### 10.2 Polish & Bug Fixes

#### Task 7.3: Loading States
```
Rà soát tất cả pages:
- Có loading spinner khi fetch data
- Có error state khi API fail
- Có empty state khi không có data
- Có retry button khi error
- Server cold start: hiện "Đang kết nối server..." + animation
```

#### Task 7.4: Error Handling
```
Rà soát:
- Network error → "Không có kết nối mạng"
- Server error (5xx) → "Lỗi server, vui lòng thử lại"
- Validation error (4xx) → Hiện message cụ thể
- Token expired → Auto refresh → Nếu fail → Redirect login
- Render timeout → "Server đang khởi động, vui lòng đợi..."
```

#### Task 7.5: Navigation Flow
```
Rà soát:
- App start → Splash → check token → đúng route
- Login → check company status → đúng screen
- Pending → auto-poll → approved → navigate Home
- Logout → clear all data → Welcome
- Deep link QR → join group (nếu logged in)
- Back button handling → không back về login sau khi login
```

#### Task 7.6: Offline Support
```
Rà soát:
- Step counting chạy offline ✓
- Steps sync queue khi offline ✓
- Chat messages queue khi offline
- Conversations list cache
- Groups list cache
- Auto-sync khi reconnect
```

### 10.3 Demo Preparation

#### Task 7.7: Seed Demo Data
```
File: src/scripts/seedDemoData.js

Tạo data demo:
1. Super Admin account (đã có từ Task 2.3)
2. 2 Companies (1 approved, 1 pending):
   - "Công ty ABC Technology" (approved, code: "ABC123")
   - "Công ty XYZ Corp" (pending)
3. Company ABC admin + 5 members
4. 2 Groups trong ABC:
   - "Team Chạy Sáng" (3 members)
   - "Team Fitness" (4 members)
5. Một vài messages trong group chat
6. 1 Active contest trong "Team Chạy Sáng" với step data
7. Leaderboard data
```

#### Task 7.8: Demo Flow Script
```
Demo Flow (trình tự trình bày):

1. 📱 WEB PORTAL - Super Admin
   a. Login super admin
   b. Dashboard → thấy stats
   c. Company list → thấy "XYZ Corp" pending
   d. Approve "XYZ Corp" → status chuyển xanh + có company code

2. 📱 FLUTTER APP - Company Admin
   a. Mở app → Login admin "XYZ Corp"
   b. Trước approve → thấy "Chờ phê duyệt"
   c. Sau approve → auto navigate Home
   d. Xem Profile → thấy mã công ty

3. 📱 FLUTTER APP - Tạo nhóm
   a. Tạo nhóm "Team Demo" + chọn members
   b. QR code hiện ra
   c. Tìm kiếm nhóm bằng tên

4. 📱 FLUTTER APP - Chat
   a. Vào group chat → gửi tin nhắn text
   b. Gửi emoji
   c. Gửi hình ảnh
   d. Chat 1v1 → tap avatar → chat direct
   e. (2 devices: thấy tin nhắn realtime)

5. 📱 FLUTTER APP - Step Counter
   a. Start step counter → notification hiện
   b. Đi bộ → số bước tăng
   c. Sync → server nhận data

6. 📱 FLUTTER APP - Cuộc thi
   a. Tạo cuộc thi "Thử thách 7 ngày"
   b. Leaderboard hiện → thấy ranking
   c. Đi bộ → leaderboard update realtime
```

### 10.4 Verify Sprint 7

```
✅ Checklist:
□ Toàn bộ flow E2E hoạt động mượt
□ Không có crash / unhandled error
□ Loading states đầy đủ
□ Offline → online transition mượt
□ Step counter chạy ngầm ổn định (test 1 tiếng)
□ Chat realtime ổn định (test 2 devices)
□ Leaderboard update đúng
□ Render cold start → client handle đúng (loading, retry)
□ Demo data ready
□ Demo flow diễn ra thành công
```

---

## 11. Task Dependencies

```
Sprint 0 (Setup)
  │
  ├── Task 0.1-0.5: Backend setup
  ├── Task 0.6-0.8: Flutter setup
  └── Task 0.9-0.10: Web setup
  │
  ▼
Sprint 1 (Auth) ← depends on Sprint 0
  │
  ├── Task 1.1-1.2: Models
  ├── Task 1.3-1.5: Middleware
  ├── Task 1.6-1.10: Auth APIs
  ├── Task 1.11: Company status API
  └── Task 1.12-1.14: Flutter Auth UI
  │
  ├──────────────┬──────────────┐
  ▼              ▼              ▼
Sprint 2       Sprint 3       Sprint 5
(Admin Web)    (Groups)       (Steps)
  │              │              │
  │              ▼              │
  │            Sprint 4         │
  │            (Chat)           │
  │              │              │
  │              └──────┬───────┘
  │                     ▼
  │                Sprint 6
  │               (Contests)
  │                     │
  └─────────────────────┘
              │
              ▼
          Sprint 7
        (Integration)
```

---

## 12. Testing Strategy

### 12.1 Backend Testing

| Layer | Tool | Mô tả |
|---|---|---|
| API Testing | **Postman Collection** | Test tất cả endpoints manually |
| Auto Test | **Jest + Supertest** | Unit test cho services, integration test cho routes |

**Postman Collection structure:**
```
WalkTogether API/
├── Auth/
│   ├── Register User
│   ├── Register Company
│   ├── Login
│   ├── Refresh Token
│   ├── Get Me
│   └── Logout
├── Admin/
│   ├── Get Companies
│   ├── Approve Company
│   ├── Reject Company
│   └── Get Stats
├── Company/
│   ├── Get Status
│   ├── Get Members
│   └── Get Profile
├── Groups/
│   ├── Create Group
│   ├── Get Groups
│   ├── Search Groups
│   ├── Add Members
│   └── Remove Member
├── Chat/
│   ├── Get Conversations
│   ├── Create Direct
│   ├── Get Messages
│   ├── Send Message
│   └── Upload Image
├── Steps/
│   ├── Sync Steps
│   ├── Get Today
│   └── Get History
└── Contests/
    ├── Create Contest
    ├── Get Leaderboard
    └── Cancel Contest
```

### 12.2 Flutter Testing

| Layer | Mô tả |
|---|---|
| **Widget test** | Test individual widgets render đúng |
| **BLoC test** | Test BLoC logic: events → states |
| **Manual test** | Test trên device thật (step counter cần sensor) |

### 12.3 E2E Testing (Manual)

Dùng **2 thiết bị thật** (hoặc 1 device + 1 emulator):
- Device A: Company Admin
- Device B: Member
- Test chat realtime, leaderboard realtime

---

## 13. Demo Checklist

### Pre-Demo

```
□ Render server running (ping health check)
□ MongoDB Atlas accessible
□ Cloudinary accessible
□ Demo data seeded
□ Super Admin credentials ready
□ 2 test devices charged & ready
□ Web portal URL accessible
□ Stable internet connection
□ Screen recording ready (backup)
```

### Demo Accounts

```
Super Admin (Web):
  Email: admin@walktogether.com
  Pass: Admin@2026

Company Admin (App):
  Email: admin@abctech.com
  Pass: Demo@2026
  Company: ABC Technology (approved)

Member 1 (App):
  Email: member1@abctech.com
  Pass: Demo@2026

Member 2 (App):
  Email: member2@abctech.com
  Pass: Demo@2026

Pending Company Admin (App):
  Email: admin@xyzcorp.com
  Pass: Demo@2026
  Company: XYZ Corp (pending)
```

### Demo Flow Duration: ~15 phút

```
1. [2 min] Web Portal: Login → Dashboard → Approve company
2. [2 min] App: Login pending → chờ → approved → Home
3. [2 min] App: Tạo nhóm + QR code
4. [3 min] App: Chat nhóm + 1v1 (2 devices)
5. [2 min] App: Step counter + sync
6. [3 min] App: Tạo cuộc thi + leaderboard realtime
7. [1 min] Q&A / Buffer
```

---

> **Plan này sẽ được cập nhật trong quá trình implement.**  
> **Mỗi Sprint hoàn thành → verify checklist → move to next Sprint.**  
> **Xem [MASTER_PLAN.md](MASTER_PLAN.md) cho Phase 2 & Phase 3 plan.**
