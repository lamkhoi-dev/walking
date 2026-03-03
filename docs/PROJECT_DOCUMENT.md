# 🏃 WalkTogether - Project Document

> **Version**: 1.0  
> **Created**: 2026-03-02  
> **Status**: Planning Phase  
> **Author**: Dev Team

---

## 📋 Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Tech Stack](#2-tech-stack)
3. [Kiến trúc hệ thống](#3-kiến-trúc-hệ-thống)
4. [Phân quyền & Roles](#4-phân-quyền--roles)
5. [Database Schema](#5-database-schema)
6. [API Design](#6-api-design)
7. [Chi tiết tính năng Giai đoạn 1](#7-chi-tiết-tính-năng-giai-đoạn-1)
8. [Chi tiết tính năng Giai đoạn 2](#8-chi-tiết-tính-năng-giai-đoạn-2)
9. [Chi tiết tính năng Giai đoạn 3](#9-chi-tiết-tính-năng-giai-đoạn-3)
10. [WebSocket Events](#10-websocket-events)
11. [Deployment & Infrastructure](#11-deployment--infrastructure)
12. [Lưu ý kỹ thuật quan trọng](#12-lưu-ý-kỹ-thuật-quan-trọng)
13. [App Navigation Flow](#13-app-navigation-flow)

---

## 1. Tổng quan dự án

### 1.1 Mô tả
**WalkTogether** là ứng dụng đếm bước chân / chạy bộ dành cho **doanh nghiệp**. Công ty đăng ký trên web portal, sau khi được phê duyệt, admin công ty có thể tạo nhóm cho nhân viên, tổ chức cuộc thi chạy bộ, và theo dõi bảng xếp hạng. App hỗ trợ chạy ngầm (foreground service) để đếm bước chân liên tục.

### 1.2 Đối tượng sử dụng
| Đối tượng | Nền tảng | Mô tả |
|---|---|---|
| **Super Admin** | Web Portal | Quản lý & phê duyệt công ty đăng ký |
| **Admin Công ty** | Mobile App | Quản lý nhóm, thành viên, cuộc thi *(chỉ khi công ty đã được phê duyệt, nếu chưa duyệt chỉ thấy màn hình chờ)* |
| **Member (Nhân viên)** | Mobile App | Tham gia nhóm, cuộc thi, chat, đếm bước |

### 1.3 Roadmap tổng quan
| Giai đoạn | Mô tả | Ưu tiên |
|---|---|---|
| **Phase 1** | Core: Auth, Company, Group, Chat, Contest, Step Counter | 🔴 HIGH - LOCKED |
| **Phase 2** | Daily Goals, Leaderboard tổng thể, Profile | 🟡 MEDIUM |
| **Phase 3** | Social: Posts, Videos, Likes, Comments, Share | 🟢 LOW |

---

## 2. Tech Stack

### 2.1 Mobile App (Flutter)
| Thành phần | Công nghệ | Mục đích |
|---|---|---|
| Framework | **Flutter 3.x** | Cross-platform (Android + iOS) |
| State Management | **BLoC / Cubit** | Quản lý state có cấu trúc, dễ test |
| Navigation | **GoRouter** | Declarative routing |
| HTTP Client | **Dio** | API calls với interceptors, retry logic |
| WebSocket | **socket_io_client** | Realtime chat & leaderboard |
| Local Storage | **SharedPreferences + Hive** | Token, cache, offline data |
| Step Counter | **pedometer_2 + foreground_service** | Đếm bước chạy ngầm |
| Notifications | **flutter_local_notifications** | Hiển thị thông báo bước chân |
| Image | **image_picker + cached_network_image** | Chọn & cache hình ảnh |
| QR Code | **qr_flutter + mobile_scanner** | Tạo & quét QR nhóm |

### 2.2 Web Portal (React)
| Thành phần | Công nghệ | Mục đích |
|---|---|---|
| Framework | **React 18 + Vite** | SPA cho Super Admin |
| UI Library | **Ant Design / MUI** | Component library |
| State | **React Query (TanStack)** | Server state management |
| HTTP | **Axios** | API calls |
| Router | **React Router v6** | Routing |

### 2.3 Backend (Node.js)
| Thành phần | Công nghệ | Mục đích |
|---|---|---|
| Runtime | **Node.js 20 LTS** | Server runtime |
| Framework | **Express.js** | HTTP server |
| WebSocket | **Socket.IO** | Realtime communication |
| Database ODM | **Mongoose** | MongoDB object modeling |
| Auth | **JWT (jsonwebtoken)** | Authentication & Authorization |
| Validation | **Joi / express-validator** | Input validation |
| File Upload | **Multer + Cloudinary** | Upload & lưu trữ hình ảnh |
| Cron Jobs | **node-cron** | Tổng hợp bước cuối ngày, cleanup |
| Rate Limiting | **express-rate-limit** | Bảo vệ API |
| Logging | **Winston** | Structured logging |

### 2.4 Database & Storage
| Thành phần | Công nghệ | Mục đích |
|---|---|---|
| Primary DB | **MongoDB Atlas** | Main database (free tier cho demo) |
| File Storage | **Cloudinary** | Lưu hình ảnh chat, avatar (free tier) |
| Caching | **Node-cache (in-memory)** | Cache leaderboard, company info |

---

## 3. Kiến trúc hệ thống

### 3.1 Tổng quan kiến trúc

```
┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │     │  React Web      │
│   (Mobile)      │     │  (Super Admin)  │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │  HTTPS / WSS          │  HTTPS
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────┐
│         Node.js Backend (Express)       │
│  ┌───────────┐  ┌────────────────────┐  │
│  │  REST API │  │  Socket.IO Server  │  │
│  └───────────┘  └────────────────────┘  │
│  ┌───────────┐  ┌────────────────────┐  │
│  │   Auth    │  │   Cron Jobs        │  │
│  │ Middleware │  │ (Step aggregation) │  │
│  └───────────┘  └────────────────────┘  │
└────────┬────────────────────┬───────────┘
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌───────────────────┐
│  MongoDB Atlas  │  │   Cloudinary      │
│  (Database)     │  │   (Image Storage) │
└─────────────────┘  └───────────────────┘
```

### 3.2 Folder Structure — Backend

```
server/
├── src/
│   ├── config/
│   │   ├── db.js                 # MongoDB connection
│   │   ├── cloudinary.js         # Cloudinary config
│   │   ├── socket.js             # Socket.IO setup
│   │   └── env.js                # Environment variables
│   ├── middleware/
│   │   ├── auth.js               # JWT verify middleware
│   │   ├── role.js               # Role-based access control
│   │   ├── companyStatus.js      # Check company approved (chặn pending/rejected/suspended)
│   │   ├── upload.js             # Multer config
│   │   ├── validate.js           # Request validation
│   │   ├── rateLimiter.js        # Rate limiting
│   │   └── errorHandler.js       # Global error handler
│   ├── models/
│   │   ├── User.js
│   │   ├── Company.js
│   │   ├── Group.js
│   │   ├── Message.js
│   │   ├── Conversation.js
│   │   ├── Contest.js
│   │   ├── StepRecord.js
│   │   └── Leaderboard.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── admin.routes.js       # Super Admin routes
│   │   ├── company.routes.js
│   │   ├── group.routes.js
│   │   ├── chat.routes.js
│   │   ├── contest.routes.js
│   │   └── step.routes.js
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── admin.controller.js
│   │   ├── company.controller.js
│   │   ├── group.controller.js
│   │   ├── chat.controller.js
│   │   ├── contest.controller.js
│   │   └── step.controller.js
│   ├── services/
│   │   ├── auth.service.js
│   │   ├── company.service.js
│   │   ├── group.service.js
│   │   ├── chat.service.js
│   │   ├── contest.service.js
│   │   ├── step.service.js
│   │   └── leaderboard.service.js
│   ├── socket/
│   │   ├── index.js              # Socket.IO initialization
│   │   ├── chatHandler.js        # Chat events
│   │   ├── stepHandler.js        # Step sync events
│   │   └── leaderboardHandler.js # Leaderboard events
│   ├── utils/
│   │   ├── generateCompanyCode.js
│   │   ├── generateQRData.js
│   │   ├── response.js           # Standard response format
│   │   └── constants.js
│   ├── jobs/
│   │   ├── stepAggregation.js    # Cron: tổng hợp bước cuối ngày
│   │   └── contestChecker.js     # Cron: check contest start/end
│   └── app.js                    # Express app setup
├── .env
├── .env.example
├── package.json
└── server.js                     # Entry point
```

### 3.3 Folder Structure — Flutter App

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── api_endpoints.dart
│   │   └── app_constants.dart
│   ├── network/
│   │   ├── dio_client.dart       # Dio setup + interceptors
│   │   ├── api_response.dart     # Generic response model
│   │   └── api_exceptions.dart
│   ├── socket/
│   │   └── socket_service.dart   # Socket.IO client singleton
│   ├── services/
│   │   ├── step_counter_service.dart   # Foreground service
│   │   ├── notification_service.dart
│   │   └── storage_service.dart        # Local storage
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── helpers.dart
│   │   └── date_utils.dart
│   └── router/
│       └── app_router.dart       # GoRouter config
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   └── entities/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   ├── register_page.dart
│   │       │   ├── welcome_page.dart
│   │       │   ├── pending_approval_page.dart   # Chờ phê duyệt
│   │       │   ├── rejected_page.dart           # Bị từ chối
│   │       │   └── suspended_page.dart          # Bị tạm ngưng
│   │       └── widgets/
│   ├── home/
│   │   └── presentation/
│   │       ├── pages/
│   │       └── widgets/
│   ├── group/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── chat/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── contest/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── step_tracker/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   └── widgets/
│       ├── custom_app_bar.dart
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       ├── loading_widget.dart
│       ├── error_widget.dart
│       └── avatar_widget.dart
└── main.dart
```

### 3.4 Folder Structure — React Web Portal

```
web-admin/
├── src/
│   ├── api/
│   │   ├── axiosClient.js
│   │   ├── authApi.js
│   │   └── companyApi.js
│   ├── components/
│   │   ├── Layout/
│   │   ├── CompanyTable/
│   │   ├── CompanyDetail/
│   │   └── common/
│   ├── pages/
│   │   ├── LoginPage.jsx
│   │   ├── DashboardPage.jsx
│   │   ├── CompanyListPage.jsx
│   │   └── CompanyDetailPage.jsx
│   ├── hooks/
│   │   ├── useAuth.js
│   │   └── useCompanies.js
│   ├── context/
│   │   └── AuthContext.jsx
│   ├── utils/
│   │   └── helpers.js
│   ├── App.jsx
│   └── main.jsx
├── .env
├── package.json
└── vite.config.js
```

---

## 4. Phân quyền & Roles

### 4.1 Role Definition

| Role | Code | Nền tảng | Mô tả |
|---|---|---|---|
| **Super Admin** | `super_admin` | Web Portal | Phê duyệt/quản lý công ty, xem statistics |
| **Company Admin** | `company_admin` | Mobile App | Quản lý nhóm, thành viên, cuộc thi trong công ty. **Yêu cầu: company.status = 'approved'**. Nếu chưa duyệt → chỉ thấy màn hình chờ. |
| **Member** | `member` | Mobile App | Tham gia nhóm, cuộc thi, chat, đếm bước. **Yêu cầu: company.status = 'approved'**. |

### 4.2 Permission Matrix

| Hành động | Super Admin | Company Admin | Member |
|---|---|---|---|
| Phê duyệt công ty | ✅ | ❌ | ❌ |
| Xem danh sách công ty (web) | ✅ | ❌ | ❌ |
| Xem mã công ty | ✅ | ✅ | ❌ |
| Tạo nhóm | ❌ | ✅ | ❌ |
| Thêm thành viên vào nhóm | ❌ | ✅ | ❌ |
| Tạo cuộc thi | ❌ | ✅ | ❌ |
| Xem nhóm | ❌ | ✅ | ✅ |
| Tìm kiếm nhóm | ❌ | ✅ | ✅ |
| Chat nhóm / 1v1 | ❌ | ✅ | ✅ |
| Gửi hình ảnh trong chat | ❌ | ✅ | ✅ |
| Xem leaderboard | ❌ | ✅ | ✅ |
| Đếm bước | ❌ | ✅ | ✅ |
| Xem profile | ❌ | ✅ | ✅ |

> ⚠️ **Lưu ý quan trọng**: Tất cả quyền của Company Admin và Member ở trên chỉ áp dụng khi **company.status === 'approved'**.
> - Nếu công ty chưa duyệt (`pending`): Company Admin chỉ thấy màn hình "Chờ phê duyệt", không truy cập được bất kỳ tính năng nào.
> - Nếu công ty bị từ chối (`rejected`): Company Admin thấy màn hình "Bị từ chối".
> - Nếu công ty bị tạm ngưng (`suspended`): Tất cả users (Admin + Member) thấy màn hình "Tạm ngưng".
> - Backend cũng cần middleware `requireApprovedCompany` để chặn API calls từ công ty chưa duyệt.

---

## 5. Database Schema

### 5.1 Collection: `users`

```javascript
{
  _id: ObjectId,
  email: String,              // unique, nullable (nếu dùng SĐT)
  phone: String,              // unique, nullable (nếu dùng email)
  password: String,           // bcrypt hashed
  fullName: String,
  avatar: String,             // Cloudinary URL
  role: String,               // enum: ['super_admin', 'company_admin', 'member']
  companyId: ObjectId,        // ref: companies (null cho super_admin)
  companyCode: String,        // mã công ty lúc đăng ký
  isActive: Boolean,          // default: true
  deviceToken: String,        // cho push notification sau này
  lastOnline: Date,
  createdAt: Date,
  updatedAt: Date
}

// Indexes:
// { email: 1 } unique sparse
// { phone: 1 } unique sparse
// { companyId: 1 }
// { role: 1 }
```

### 5.2 Collection: `companies`

```javascript
{
  _id: ObjectId,
  name: String,               // Tên công ty
  email: String,              // Email đăng ký
  phone: String,              // SĐT liên hệ
  address: String,
  description: String,
  logo: String,               // Cloudinary URL
  code: String,               // Mã công ty (unique, 6 ký tự, chữ + số, dễ nhớ)
  status: String,             // enum: ['pending', 'approved', 'rejected', 'suspended']
  adminId: ObjectId,          // ref: users - admin chính của công ty
  totalMembers: Number,       // cached count
  createdAt: Date,
  updatedAt: Date
}

// Indexes:
// { code: 1 } unique
// { status: 1 }
// { adminId: 1 }
```

### 5.3 Collection: `groups`

```javascript
{
  _id: ObjectId,
  name: String,               // Tên nhóm
  description: String,
  avatar: String,             // Cloudinary URL
  companyId: ObjectId,        // ref: companies
  createdBy: ObjectId,        // ref: users (admin)
  members: [ObjectId],        // ref: users
  qrCode: String,             // QR data string (group ID encoded)
  isActive: Boolean,          // default: true
  totalMembers: Number,       // cached count
  createdAt: Date,
  updatedAt: Date
}

// Indexes:
// { companyId: 1 }
// { name: 'text' }         // text index cho tìm kiếm
// { members: 1 }
// { 'name': 1, companyId: 1 }
```

### 5.4 Collection: `conversations`

```javascript
{
  _id: ObjectId,
  type: String,               // enum: ['group', 'direct']
  groupId: ObjectId,          // ref: groups (nếu type = 'group')
  participants: [ObjectId],   // ref: users (cho direct chat, 2 users)
  companyId: ObjectId,        // ref: companies
  lastMessage: {
    content: String,
    senderId: ObjectId,
    type: String,             // 'text', 'image'
    createdAt: Date
  },
  createdAt: Date,
  updatedAt: Date
}

// Indexes:
// { groupId: 1 } sparse
// { participants: 1 }
// { companyId: 1 }
// { updatedAt: -1 }
```

### 5.5 Collection: `messages`

```javascript
{
  _id: ObjectId,
  conversationId: ObjectId,   // ref: conversations
  senderId: ObjectId,         // ref: users
  type: String,               // enum: ['text', 'image', 'system']
  content: String,            // text content hoặc image URL
  imageUrl: String,           // Cloudinary URL (nếu type = 'image')
  readBy: [                   // tracking đã đọc
    {
      userId: ObjectId,
      readAt: Date
    }
  ],
  isDeleted: Boolean,         // soft delete
  createdAt: Date
}

// Indexes:
// { conversationId: 1, createdAt: -1 }
// { senderId: 1 }
```

### 5.6 Collection: `contests`

```javascript
{
  _id: ObjectId,
  name: String,
  description: String,
  groupId: ObjectId,          // ref: groups
  companyId: ObjectId,        // ref: companies
  createdBy: ObjectId,        // ref: users (admin)
  startDate: Date,
  endDate: Date,
  status: String,             // enum: ['upcoming', 'active', 'completed', 'cancelled']
  participants: [ObjectId],   // ref: users (auto-add all group members)
  createdAt: Date,
  updatedAt: Date
}

// Indexes:
// { groupId: 1, status: 1 }
// { companyId: 1 }
// { startDate: 1, endDate: 1 }
// { status: 1 }
```

### 5.7 Collection: `step_records`

```javascript
{
  _id: ObjectId,
  userId: ObjectId,           // ref: users
  companyId: ObjectId,        // ref: companies
  date: String,               // format: 'YYYY-MM-DD' → partition key
  steps: Number,              // tổng số bước trong ngày
  hourlySteps: [              // chi tiết theo giờ (optional, cho analytics)
    {
      hour: Number,           // 0-23
      steps: Number
    }
  ],
  distance: Number,           // khoảng cách (m), ước tính từ steps
  calories: Number,           // calories, ước tính từ steps
  syncedAt: Date,             // lần sync cuối
  createdAt: Date,
  updatedAt: Date
}

// Indexes:
// { userId: 1, date: 1 } unique compound
// { companyId: 1, date: 1 }
// { date: 1 }
```

### 5.8 Collection: `contest_leaderboards`

```javascript
{
  _id: ObjectId,
  contestId: ObjectId,        // ref: contests
  userId: ObjectId,           // ref: users
  totalSteps: Number,         // tổng bước trong cuộc thi
  dailySteps: [               // chi tiết theo ngày
    {
      date: String,
      steps: Number
    }
  ],
  rank: Number,               // thứ hạng (cập nhật bởi cron hoặc realtime)
  lastUpdated: Date
}

// Indexes:
// { contestId: 1, totalSteps: -1 }    // cho sorting leaderboard
// { contestId: 1, userId: 1 } unique
// { userId: 1 }
```

---

## 6. API Design

### 6.1 Base Configuration

- **Base URL**: `https://walktogether-api.onrender.com/api/v1`
- **Auth**: Bearer Token (JWT) trong header `Authorization`
- **Response format**:

```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "pagination": {          // optional, cho list APIs
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

- **Error format**:

```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "VALIDATION_ERROR",
    "details": [ ... ]
  }
}
```

### 6.2 Auth APIs

| Method | Endpoint | Mô tả | Auth |
|---|---|---|---|
| POST | `/auth/register` | Đăng ký user (email/SĐT + pass + mã cty) | ❌ |
| POST | `/auth/register-company` | Đăng ký công ty (từ web) | ❌ |
| POST | `/auth/login` | Đăng nhập | ❌ |
| POST | `/auth/refresh-token` | Refresh access token | 🔑 Refresh Token |
| POST | `/auth/logout` | Đăng xuất | ✅ |
| GET | `/auth/me` | Lấy thông tin user hiện tại | ✅ |
| PUT | `/auth/change-password` | Đổi mật khẩu | ✅ |

#### Chi tiết API - Register User
```
POST /auth/register
Body:
{
  "email": "user@example.com",     // hoặc phone
  "phone": "0901234567",           // hoặc email
  "password": "Abc@1234",
  "fullName": "Nguyễn Văn A",
  "companyCode": "WLK123"          // mã công ty 
}

Response 201:
{
  "success": true,
  "message": "Đăng ký thành công",
  "data": {
    "user": { ... },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

#### Chi tiết API - Login
```
POST /auth/login
Body:
{
  "identifier": "user@example.com",  // email hoặc SĐT
  "password": "Abc@1234"
}

Response 200 (công ty đã duyệt / member / super_admin):
{
  "success": true,
  "data": {
    "user": { _id, fullName, email, phone, role, avatar, companyId },
    "company": { _id, name, status, code },  // null cho super_admin
    "accessToken": "eyJ...",       // expires: 7d
    "refreshToken": "eyJ..."       // expires: 30d
  }
}

Response 200 (company_admin nhưng công ty CHƯA duyệt):
{
  "success": true,
  "data": {
    "user": { _id, fullName, email, phone, role, avatar, companyId },
    "company": { _id, name, status: "pending", code: null },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}

Logic phía Client:
- Login thành công → check company.status
  - Nếu role === 'company_admin' && company.status === 'pending'
    → Navigate đến màn hình "Chờ phê duyệt" (PendingApprovalScreen)
  - Nếu role === 'company_admin' && company.status === 'rejected'
    → Navigate đến màn hình "Bị từ chối" (RejectedScreen)
  - Nếu role === 'company_admin' && company.status === 'suspended'
    → Navigate đến màn hình "Bị tạm ngưng" (SuspendedScreen)
  - Nếu company.status === 'approved' hoặc role !== 'company_admin'
    → Navigate đến Home bình thường
```

> ⚠️ **Lưu ý Render**: Access token expire = **7 ngày** (thay vì 15 phút) để giảm refresh calls. Refresh token = **30 ngày**. Do cold start ~1 phút, client cần timeout ít nhất **90 giây**.

### 6.3 Super Admin APIs (Web Portal)

| Method | Endpoint | Mô tả | Auth |
|---|---|---|---|
| GET | `/admin/companies` | Danh sách công ty (filter, search, pagination) | 🔑 Super Admin |
| GET | `/admin/companies/:id` | Chi tiết 1 công ty | 🔑 Super Admin |
| PUT | `/admin/companies/:id/approve` | Phê duyệt công ty | 🔑 Super Admin |
| PUT | `/admin/companies/:id/reject` | Từ chối công ty | 🔑 Super Admin |
| PUT | `/admin/companies/:id/suspend` | Tạm ngưng công ty | 🔑 Super Admin |
| GET | `/admin/stats` | Dashboard statistics | 🔑 Super Admin |

### 6.4 Company APIs

| Method | Endpoint | Mô tả | Auth |
|---|---|---|---|
| GET | `/company/profile` | Thông tin công ty hiện tại | 🔑 Admin/Member |
| PUT | `/company/profile` | Cập nhật thông tin công ty | 🔑 Admin |
| GET | `/company/members` | Danh sách thành viên công ty | 🔑 Admin/Member |
| GET | `/company/code` | Lấy mã công ty | 🔑 Admin |
| GET | `/company/status` | Check trạng thái phê duyệt công ty | 🔑 Admin |
| DELETE | `/company/members/:userId` | Xoá thành viên khỏi công ty | 🔑 Admin |

#### Chi tiết API - Check Company Status
```
GET /company/status

Response 200:
{
  "success": true,
  "data": {
    "companyId": "...",
    "name": "Công ty ABC",
    "status": "pending",        // 'pending' | 'approved' | 'rejected' | 'suspended'
    "code": null,               // null nếu chưa approved, có giá trị khi approved
    "updatedAt": "2026-03-02T..."
  }
}

Mục đích:
- Company admin ở màn hình "Chờ phê duyệt" sẽ gọi API này
  để kiểm tra định kỳ (pull-to-refresh hoặc mỗi 30 giây)
- Khi status chuyển sang 'approved' → tự động navigate đến Home
```

### 6.5 Group APIs

| Method | Endpoint | Mô tả | Auth |
|---|---|---|---|
| POST | `/groups` | Tạo nhóm mới | 🔑 Admin |
| GET | `/groups` | Danh sách nhóm (của user) | 🔑 Admin/Member |
| GET | `/groups/:id` | Chi tiết nhóm | 🔑 Admin/Member |
| PUT | `/groups/:id` | Cập nhật nhóm | 🔑 Admin |
| DELETE | `/groups/:id` | Xoá nhóm (soft delete) | 🔑 Admin |
| POST | `/groups/:id/members` | Thêm thành viên vào nhóm | 🔑 Admin |
| DELETE | `/groups/:id/members/:userId` | Xoá thành viên khỏi nhóm | 🔑 Admin |
| GET | `/groups/search?q=keyword` | Tìm nhóm bằng tên | 🔑 Admin/Member |
| GET | `/groups/join/:qrCode` | Join nhóm bằng QR code | 🔑 Admin/Member |

#### Chi tiết API - Tạo nhóm
```
POST /groups
Body:
{
  "name": "Team Chạy Bộ Sáng",
  "description": "Nhóm chạy bộ mỗi sáng 6h",
  "memberIds": ["userId1", "userId2", "userId3"],
  "avatar": File (multipart)       // optional
}

Response 201:
{
  "success": true,
  "data": {
    "group": {
      "_id": "...",
      "name": "Team Chạy Bộ Sáng",
      "description": "...",
      "qrCode": "WLK_GRP_abc123",
      "members": [...],
      "totalMembers": 4
    }
  }
}
```

### 6.6 Chat APIs

| Method | Endpoint | Mô tả | Auth |
|---|---|---|---|
| GET | `/chat/conversations` | Danh sách conversations | ✅ |
| POST | `/chat/conversations/direct` | Tạo/lấy direct conversation | ✅ |
| GET | `/chat/conversations/:id/messages` | Lịch sử tin nhắn (pagination) | ✅ |
| POST | `/chat/conversations/:id/messages` | Gửi tin nhắn (REST fallback) | ✅ |
| POST | `/chat/conversations/:id/upload` | Upload hình ảnh | ✅ |
| PUT | `/chat/conversations/:id/read` | Đánh dấu đã đọc | ✅ |

> **Lưu ý**: Chat chủ yếu qua **WebSocket** (Socket.IO). REST APIs là fallback và cho lịch sử tin nhắn.

### 6.7 Contest APIs

| Method | Endpoint | Mô tả | Auth |
|---|---|---|---|
| POST | `/contests` | Tạo cuộc thi | 🔑 Admin |
| GET | `/contests` | Danh sách cuộc thi | ✅ |
| GET | `/contests/:id` | Chi tiết cuộc thi | ✅ |
| PUT | `/contests/:id` | Cập nhật cuộc thi | 🔑 Admin |
| DELETE | `/contests/:id` | Huỷ cuộc thi | 🔑 Admin |
| GET | `/contests/:id/leaderboard` | Bảng xếp hạng cuộc thi | ✅ |
| GET | `/contests/group/:groupId/active` | Cuộc thi đang active của nhóm | ✅ |

#### Chi tiết API - Tạo cuộc thi
```
POST /contests
Body:
{
  "name": "Thử thách 10K bước",
  "description": "Ai đi nhiều bước nhất trong 7 ngày",
  "groupId": "groupId123",
  "startDate": "2026-03-10T00:00:00Z",
  "endDate": "2026-03-17T23:59:59Z"
}

Validation:
- Không có cuộc thi active khác trong cùng nhóm
- startDate >= now
- endDate > startDate
```

### 6.8 Step APIs

| Method | Endpoint | Mô tả | Auth |
|---|---|---|---|
| POST | `/steps/sync` | Đồng bộ bước chân | ✅ |
| GET | `/steps/today` | Số bước hôm nay | ✅ |
| GET | `/steps/history?from=&to=` | Lịch sử bước (theo range) | ✅ |
| GET | `/steps/stats` | Thống kê (tuần, tháng) | ✅ |

#### Chi tiết API - Sync bước chân
```
POST /steps/sync
Body:
{
  "date": "2026-03-02",
  "steps": 8432,
  "hourlySteps": [
    { "hour": 6, "steps": 1200 },
    { "hour": 7, "steps": 2100 },
    ...
  ]
}

Logic:
- Upsert: tìm record theo userId + date, update nếu đã tồn tại
- Đồng thời cập nhật contest_leaderboards nếu user đang trong cuộc thi active
- Emit socket event để cập nhật leaderboard realtime
```

---

## 7. Chi tiết tính năng Giai đoạn 1

### 7.1 Đăng ký & Đăng nhập

#### Flow đăng ký User (Mobile App):
```
Mở app → Màn hình Welcome
  ├── [Đăng ký Doanh nghiệp] → Mở WebView/Browser → Web Portal
  └── [Đăng ký User] → Form:
       ├── Email hoặc SĐT
       ├── Mật khẩu (min 6 ký tự)
       ├── Họ tên
       └── Mã công ty (bắt buộc)
       → Validate mã công ty (check company.status === 'approved')
       → Tạo user với role 'member'
       → Auto login → Home
```

#### Flow đăng ký Công ty (Web Portal):
```
Truy cập web → Form đăng ký:
  ├── Tên công ty
  ├── Email công ty
  ├── SĐT liên hệ
  ├── Địa chỉ
  ├── Mô tả
  └── Thông tin admin (email, password, họ tên)
→ Tạo company (status: 'pending') + user (role: 'company_admin')
→ Hiển thị trên web: "Đăng ký thành công, vui lòng đợi phê duyệt"
→ Super Admin duyệt → Company status = 'approved'
→ Auto generate mã công ty (VD: "WLK7A3")
```

#### Flow Login Company Admin (Mobile App):
```
Admin công ty login trên app:

📌 Case 1: Công ty status = 'pending'
  → Login thành công (có token)
  → Navigate đến "PendingApprovalScreen":
     ┌─────────────────────────────────────┐
     │         ⏳ Đang chờ phê duyệt       │
     │                                     │
     │  Công ty của bạn đang được xem xét. │
     │  Vui lòng đợi quản trị viên phê    │
     │  duyệt để sử dụng ứng dụng.        │
     │                                     │
     │  Công ty: [Tên công ty]             │
     │  Ngày đăng ký: [dd/mm/yyyy]         │
     │                                     │
     │       [🔄 Kiểm tra lại]             │
     │       [🚪 Đăng xuất]                │
     └─────────────────────────────────────┘
  → Nút "Kiểm tra lại" gọi GET /company/status
  → Auto-check mỗi 30 giây
  → Khi status = 'approved' → navigate Home

📌 Case 2: Công ty status = 'rejected'
  → Navigate đến "RejectedScreen":
     "Đăng ký công ty đã bị từ chối.
      Vui lòng liên hệ hỗ trợ."
  → Chỉ có nút Đăng xuất

📌 Case 3: Công ty status = 'suspended'
  → Navigate đến "SuspendedScreen":
     "Công ty đã bị tạm ngưng hoạt động.
      Vui lòng liên hệ hỗ trợ."
  → Chỉ có nút Đăng xuất

📌 Case 4: Công ty status = 'approved'
  → Navigate đến Home → sử dụng bình thường
```

### 7.2 Super Admin Web Portal

**Các trang:**
1. **Login Page**: Email + Password
2. **Dashboard**: Thống kê tổng quan (tổng công ty, pending, approved, total users)
3. **Company List**: Bảng danh sách công ty có filter (status), search (tên), pagination
4. **Company Detail**: Chi tiết công ty + nút Approve/Reject/Suspend

### 7.3 Nhóm (Groups)

#### Tạo nhóm (Admin):
- Nhập tên nhóm, mô tả
- Chọn thành viên từ danh sách nhân viên công ty (multi-select with search)
- Upload avatar nhóm (optional)
- Tự động sinh QR Code cho nhóm

#### Tìm kiếm nhóm:
- **Tìm theo tên**: Search bar trên đầu trang danh sách nhóm, tìm trong phạm vi công ty
- **Tìm theo QR Code**: Nút scan QR → mở camera → quét → join nhóm (nếu cùng công ty)

### 7.4 Chat

#### Kiến trúc Chat:
```
Conversations (danh sách)
  ├── Group Chat (auto-create khi tạo nhóm)
  │   ├── Text messages
  │   ├── Emoji
  │   ├── Image (upload to Cloudinary)
  │   └── System messages (join/leave)
  └── Direct Chat (1v1)
      ├── Tạo bằng cách tap vào avatar user trong nhóm
      └── Cùng features như group chat
```

#### Chat Features:
- Gửi text + emoji (keyboard emoji)
- Gửi hình ảnh (từ gallery hoặc camera)
- Hiển thị trạng thái đã đọc
- Hiển thị "đang gõ..." (typing indicator)
- Scroll load thêm tin nhắn cũ (pagination)
- Notification khi có tin nhắn mới (khi không ở trong chat)

### 7.5 Cuộc thi (Contests)

#### Flow tạo cuộc thi:
```
Vào nhóm → Tab "Cuộc thi" → [Tạo cuộc thi]
  ├── Tên cuộc thi
  ├── Mô tả
  ├── Ngày bắt đầu (date picker)
  └── Ngày kết thúc (date picker)
  
Validation:
  - Nhóm chưa có cuộc thi active → cho phép tạo
  - Nhóm đã có cuộc thi active → hiện thông báo lỗi
  
Sau khi tạo:
  - Tất cả member trong nhóm tự động tham gia
  - Bắt đầu track steps → cập nhật leaderboard
```

#### Leaderboard cuộc thi:
- Hiển thị danh sách thành viên xếp theo tổng bước giảm dần
- Top 3 có highlight đặc biệt (vàng, bạc, đồng)
- Cập nhật: **hybrid approach**
  - Khi user sync steps → emit socket → cập nhật realtime cho users đang xem
  - Cron job cuối ngày (23:59) → tổng hợp & recalculate chính xác
- Hiển thị: Rank, Avatar, Tên, Tổng bước, Bước hôm nay

### 7.6 Đếm bước chân (Step Counter)

#### Android:
```
Foreground Service + Notification
  ├── Dùng TYPE_STEP_COUNTER sensor (hardware)
  ├── Notification: "WalkTogether đang đếm bước - Hôm nay: 5,432 bước"
  ├── Sync lên server mỗi 5 phút (nếu có internet)
  ├── Lưu offline nếu không có mạng → sync khi có mạng
  └── Battery optimization: request ignore battery optimization
```

#### iOS:
```
CoreMotion + CMPedometer
  ├── Background mode: "Motion & Fitness"
  ├── Thu thập data pedometer
  ├── Sync logic tương tự Android
  └── Notification qua local notifications
```

#### Sync Strategy:
```
App foreground:  Sync mỗi 30 giây
App background:  Sync mỗi 5 phút
No internet:     Queue locally → sync khi có mạng
Server down:     Retry với exponential backoff (do Render cold start)
                 Initial timeout: 90 giây
                 Retry: 3 lần, backoff: 5s → 15s → 30s
```

---

## 8. Chi tiết tính năng Giai đoạn 2

> ⚠️ Chưa lock in, có thể thay đổi

### 8.1 Mục tiêu hằng ngày
- Đặt mục tiêu bước chân hằng ngày (mặc định: 10,000 bước)
- Progress bar / circular indicator
- Thông báo khi đạt mục tiêu

### 8.2 Leaderboard tổng thể
- Bảng xếp hạng toàn công ty (tuần, tháng)
- Bảng xếp hạng tất cả nhóm

### 8.3 Profile
- Thông tin cá nhân, avatar
- Thống kê (tổng bước, khoảng cách, calories)
- Lịch sử cuộc thi
- Edit profile

---

## 9. Chi tiết tính năng Giai đoạn 3

> ⚠️ Chưa lock in, có thể thay đổi

### 9.1 Social Features
- Đăng bài viết (text + hình ảnh)
- Đăng video
- Like ❤️
- Comment
- Share bài viết
- Feed: hiển thị bài viết trong công ty / nhóm

---

## 10. WebSocket Events

### 10.1 Connection & Authentication

```javascript
// Client connect
const socket = io('wss://walktogether-api.onrender.com', {
  auth: { token: 'Bearer eyJ...' },
  transports: ['websocket'],
  reconnection: true,
  reconnectionDelay: 5000,      // 5s (Render cold start)
  reconnectionAttempts: 10,
  timeout: 90000                // 90s timeout cho Render
});

// Server authenticate
socket.use((socket, next) => {
  const token = socket.handshake.auth.token;
  // verify JWT → attach userId to socket
});
```

### 10.2 Chat Events

| Event | Direction | Payload | Mô tả |
|---|---|---|---|
| `chat:join` | Client → Server | `{ conversationId }` | Join conversation room |
| `chat:leave` | Client → Server | `{ conversationId }` | Leave conversation room |
| `chat:send_message` | Client → Server | `{ conversationId, type, content, imageUrl? }` | Gửi tin nhắn |
| `chat:new_message` | Server → Client | `{ message }` | Nhận tin nhắn mới |
| `chat:typing` | Client → Server | `{ conversationId, isTyping }` | Trạng thái đang gõ |
| `chat:user_typing` | Server → Client | `{ conversationId, userId, isTyping }` | Hiển thị typing |
| `chat:read` | Client → Server | `{ conversationId, messageId }` | Đánh dấu đã đọc |
| `chat:message_read` | Server → Client | `{ conversationId, userId, messageId }` | Thông báo đã đọc |

### 10.3 Step & Leaderboard Events

| Event | Direction | Payload | Mô tả |
|---|---|---|---|
| `steps:sync` | Client → Server | `{ date, steps, hourlySteps }` | Đồng bộ bước chân |
| `steps:synced` | Server → Client | `{ success, todaySteps }` | Confirm sync |
| `leaderboard:subscribe` | Client → Server | `{ contestId }` | Subscribe leaderboard |
| `leaderboard:unsubscribe` | Client → Server | `{ contestId }` | Unsubscribe |
| `leaderboard:update` | Server → Client | `{ contestId, leaderboard: [...] }` | Cập nhật BXH |

### 10.4 Online Status Events

| Event | Direction | Payload | Mô tả |
|---|---|---|---|
| `user:online` | Server → Client | `{ userId }` | User online |
| `user:offline` | Server → Client | `{ userId }` | User offline |

---

## 11. Deployment & Infrastructure

### 11.1 Deployment Architecture

```
┌─────────────────────────────────────┐
│           Render.com                │
│  ┌───────────────────────────────┐  │
│  │  Web Service (Node.js)        │  │
│  │  - Express REST API           │  │
│  │  - Socket.IO WebSocket        │  │
│  │  - Cron Jobs                  │  │
│  │  Plan: Free → Starter ($7)   │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
            │              │
            ▼              ▼
┌─────────────────┐ ┌───────────────┐
│  MongoDB Atlas  │ │  Cloudinary   │
│  (M0 Free)      │ │  (Free tier)  │
│  512MB storage  │ │  25GB storage │
└─────────────────┘ └───────────────┘

Web Portal: Vercel (Free) hoặc Render Static Site
```

### 11.2 Render Configuration

```yaml
# render.yaml
services:
  - type: web
    name: walktogether-api
    runtime: node
    plan: free                    # upgrade lên starter nếu cần
    buildCommand: npm install
    startCommand: node server.js
    envVars:
      - key: NODE_ENV
        value: production
      - key: MONGODB_URI
        sync: false
      - key: JWT_SECRET
        generateValue: true
      - key: JWT_REFRESH_SECRET
        generateValue: true
      - key: CLOUDINARY_CLOUD_NAME
        sync: false
      - key: CLOUDINARY_API_KEY
        sync: false
      - key: CLOUDINARY_API_SECRET
        sync: false
    healthCheckPath: /api/v1/health
```

### 11.3 Xử lý Render Cold Start

> ⚠️ **Quan trọng**: Render free tier có cold start ~50-60 giây

**Giải pháp phía Client (Flutter):**
```dart
// 1. Timeout config
final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 90),   // 90s
  receiveTimeout: Duration(seconds: 90),   // 90s
));

// 2. Retry interceptor
dio.interceptors.add(RetryInterceptor(
  retries: 3,
  retryDelays: [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
  ],
));

// 3. Loading UX: Hiện "Đang kết nối server..." với animation
//    thay vì error ngay lập tức
```

**Giải pháp phía Server:**
```javascript
// Health check endpoint (giữ server warm)
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});
```

**Giải pháp Keep-Alive (Optional):**
- Dùng UptimeRobot (free) ping server mỗi 14 phút
- Hoặc cron-job.org gọi health check

---

## 12. Lưu ý kỹ thuật quan trọng

### 12.1 Security
- Mật khẩu hash bằng **bcrypt** (salt rounds: 12)
- JWT tokens: Access (7d) + Refresh (30d)
- Input validation trên mọi endpoint
- Rate limiting: 100 req/15min cho auth, 500 req/15min cho general
- CORS: chỉ cho phép domain cụ thể
- Helmet.js cho HTTP headers
- **Middleware `requireApprovedCompany`**: Chặn tất cả API calls (trừ `/auth/*` và `/company/status`) nếu company chưa approved. Trả về `403 Forbidden` với message phù hợp theo từng status:
  - `pending` → "Công ty đang chờ phê duyệt"
  - `rejected` → "Công ty đã bị từ chối"
  - `suspended` → "Công ty đã bị tạm ngưng"

### 12.2 Error Handling
- Global error handler middleware
- Custom error classes (AppError, ValidationError, AuthError)
- Logging với Winston (info, warn, error levels)
- Không expose stack trace ở production

### 12.3 Performance
- MongoDB indexes cho mọi query phổ biến
- Pagination cho tất cả list APIs (default: 20 items)
- Image compression trước khi upload Cloudinary
- Socket.IO rooms để broadcast đúng group
- In-memory cache cho leaderboard (TTL: 30s)

### 12.4 Offline Support (Flutter)
- Lưu steps locally (Hive) khi không có mạng
- Queue messages khi offline → gửi khi có mạng
- Cache danh sách nhóm, conversations offline
- Connectivity listener → auto-sync khi reconnect

### 12.5 Step Counter Accuracy
- Dùng hardware step sensor (TYPE_STEP_COUNTER) thay vì accelerometer
- Đối chiếu với data hệ thống (Health Connect / Apple Health)
- Lưu baseline step count mỗi ngày để tính chính xác
- Xử lý reboot device (step counter reset)

---

## 📎 Appendix

### A. Company Code Generation
```
Format: 3 chữ cái + 3 số = 6 ký tự
Ví dụ: WLK123, ABC789, RUN456
Logic: Random + check unique trong DB
Loại bỏ ký tự dễ nhầm: 0/O, 1/I/L
```

### B. QR Code Data Format
```
Format: walktogether://group/{groupId}
Ví dụ: walktogether://group/65f1a2b3c4d5e6f7g8h9i0j1
Scan → deep link → join group (nếu cùng company)
```

### C. Estimation Formulas
```
Distance (m) = steps × 0.762         // avg stride length
Calories = steps × 0.04              // avg per step
Active minutes = steps / 100         // rough estimate
```

---

---

## 13. App Navigation Flow

### 13.1 Auth Guard & Company Status Check

App sử dụng **auth guard** kết hợp **company status check** để điều hướng user đúng màn hình:

```
App khởi động
  │
  ├── Không có token → WelcomeScreen (Login / Register)
  │
  └── Có token → Gọi GET /auth/me
       │
       ├── Token hết hạn → Thử refresh → Nếu fail → WelcomeScreen
       │
       └── Token hợp lệ → Check role & company status:
            │
            ├── role = 'super_admin' → ❌ (Super Admin chỉ dùng web)
            │
            ├── role = 'company_admin'
            │    ├── company.status = 'pending'   → PendingApprovalScreen
            │    ├── company.status = 'rejected'  → RejectedScreen
            │    ├── company.status = 'suspended' → SuspendedScreen
            │    └── company.status = 'approved'  → HomeScreen ✅
            │
            └── role = 'member'
                 ├── company.status = 'suspended' → SuspendedScreen
                 └── company.status = 'approved'  → HomeScreen ✅
```

### 13.2 PendingApprovalScreen — Chi tiết

**Mục đích**: Hiển thị cho company_admin khi công ty chưa được Super Admin phê duyệt.

**UI Components:**
- Icon hoặc animation chờ đợi (hourglass / loading)
- Tiêu đề: "Đang chờ phê duyệt"
- Mô tả: "Công ty của bạn đang được xem xét. Vui lòng đợi quản trị viên phê duyệt để sử dụng ứng dụng."
- Thông tin: Tên công ty, ngày đăng ký
- Nút "Kiểm tra lại" (pull-to-refresh)
- Nút "Đăng xuất"

**Logic:**
- Auto-poll `GET /company/status` mỗi **30 giây**
- Khi user nhấn "Kiểm tra lại" → gọi API ngay lập tức
- Khi `status === 'approved'`:
  - Hiển thị thông báo "Công ty đã được phê duyệt! 🎉"
  - Auto-navigate đến HomeScreen sau 2 giây
- Khi `status === 'rejected'`:
  - Navigate đến RejectedScreen

### 13.3 RejectedScreen

**UI Components:**
- Icon cảnh báo
- Tiêu đề: "Đăng ký bị từ chối"
- Mô tả: "Yêu cầu đăng ký công ty đã bị từ chối. Vui lòng liên hệ hỗ trợ để biết thêm chi tiết."
- Email/SĐT hỗ trợ
- Nút "Đăng xuất"

### 13.4 SuspendedScreen

**UI Components:**
- Icon cảnh báo
- Tiêu đề: "Công ty bị tạm ngưng"
- Mô tả: "Công ty của bạn đã bị tạm ngưng hoạt động. Vui lòng liên hệ hỗ trợ."
- Email/SĐT hỗ trợ
- Nút "Đăng xuất"

> **Lưu ý**: Member cũng bị ảnh hưởng khi công ty bị suspended → hiện SuspendedScreen.
> Nhưng member KHÔNG bị ảnh hưởng bởi trạng thái pending/rejected (vì member chỉ đăng ký được khi công ty đã approved).

---

> **Document này sẽ được cập nhật theo tiến trình phát triển.**
> **Phase 1 là LOCKED IN. Phase 2, 3 có thể thay đổi.**
