# 🏗️ WalkTogether - Master Plan (All Phases)

> **Version**: 1.0  
> **Created**: 2026-03-02  
> **Reference**: PROJECT_DOCUMENT.md  
> **Chi tiết Phase 1**: Xem [PHASE1_IMPLEMENTATION_PLAN.md](PHASE1_IMPLEMENTATION_PLAN.md)

---

## 📋 Mục lục

1. [Tổng quan 3 Phases](#1-tổng-quan-3-phases)
2. [Phân tích xung đột giữa các Phases](#2-phân-tích-xung-đột-giữa-các-phases)
3. [Kiến trúc mở rộng — Thiết kế từ Phase 1](#3-kiến-trúc-mở-rộng--thiết-kế-từ-phase-1)
4. [Phase 1 — Core Business (LOCKED)](#4-phase-1--core-business-locked)
5. [Phase 2 — Personal & Analytics](#5-phase-2--personal--analytics)
6. [Phase 3 — Social Platform](#6-phase-3--social-platform)
7. [Database Schema Evolution](#7-database-schema-evolution)
8. [API Evolution](#8-api-evolution)
9. [Navigation Evolution](#9-navigation-evolution)

---

## 1. Tổng quan 3 Phases

```
Phase 1 (LOCKED ✅)           Phase 2 (~66%)              Phase 3
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ ✅ Auth System    │    │ ✅ Daily Goals(UI)│    │ 📱 Social Feed    │
│ ✅ Company Mgmt   │    │ ❌ Global Leader  │    │ 📝 Posts (text)   │
│ ✅ Groups         │    │    board           │    │ 🖼️ Posts (image)  │
│ ✅ Chat (Group+DM)│    │ ❌ Full Profile   │    │ 🎥 Posts (video)  │
│ ✅ Step Counter   │    │ ✅ Statistics     │    │ ❤️ Likes           │
│ ✅ Contests       │    │ ✅ Charts/Graphs  │    │ 💬 Comments       │
│ ✅ Contest Leader  │    │ ❌ Push Notif    │    │ 🔄 Share          │
│    board          │    │ ✅ Settings       │    │ 🔍 Discovery      │
│ ✅ Web Admin      │    │                   │    │                   │
└──────────────────┘    └──────────────────┘    └──────────────────┘
       │                        │                        │
       │ Foundation             │ Enhancement            │ New Platform
       │ (build from scratch)   │ (extend existing)      │ (add new module)
       ▼                        ▼                        ▼
   Backend + App +           Mostly App +             New Backend +
   Web Portal                some new APIs            App features
```

### Tính chất mỗi Phase

| Phase | Tính chất | Ảnh hưởng Phase trước | Rủi ro xung đột |
|---|---|---|---|
| **Phase 1** | Xây nền tảng | — | — |
| **Phase 2** | **Mở rộng** Phase 1 | Thêm fields/APIs mới, KHÔNG sửa Phase 1 | 🟢 **Rất thấp** |
| **Phase 3** | **Module mới** hoàn toàn | Thêm collections/features mới, KHÔNG sửa Phase 1-2 | 🟢 **Rất thấp** |

---

## 2. Phân tích xung đột giữa các Phases

### 2.1 Phase 1 → Phase 2: CÓ XUNG ĐỘT KHÔNG?

**Kết luận: 🟢 KHÔNG — Phase 2 là ADDITIVE (thêm mới), không sửa đổi Phase 1.**

| Tính năng Phase 2 | Liên quan Phase 1 | Xung đột? | Cách xử lý |
|---|---|---|---|
| **Daily Goals** | Dùng `step_records` (đã có) | ❌ Không | Thêm collection `user_settings` mới để lưu goal target. Step records không thay đổi. |
| **Global Leaderboard** | Dùng `step_records` (đã có) | ❌ Không | Thêm API aggregation mới, query từ step_records hiện tại. Không sửa gì. |
| **Full Profile** | Dùng `users` model (đã có) | ⚠️ Rất nhỏ | Thêm fields mới vào User model (height, weight, dateOfBirth). Mongoose cho phép thêm field mà không ảnh hưởng data cũ. |
| **Statistics/Charts** | Dùng `step_records` (đã có) | ❌ Không | Read-only aggregation, không sửa gì. |
| **Push Notification** | `deviceToken` đã có trong User model | ❌ Không | Chỉ cần integrate Firebase Cloud Messaging, model đã sẵn sàng. |
| **Settings** | — | ❌ Không | Collection mới `user_settings`. |
| **Bottom Navigation** | 4 tabs đã có | ⚠️ Nhỏ | Tab "Activity" mở rộng thêm Daily Goals UI. Không cần thêm tab mới. |

### 2.2 Phase 1 → Phase 3: CÓ XUNG ĐỘT KHÔNG?

**Kết luận: 🟢 KHÔNG — Phase 3 là MODULE MỚI hoàn toàn.**

| Tính năng Phase 3 | Liên quan Phase 1 | Xung đột? | Cách xử lý |
|---|---|---|---|
| **Social Feed** | — | ❌ Không | Collections hoàn toàn mới: `posts`, `comments`, `likes` |
| **Posts (text/image/video)** | Dùng Cloudinary (đã setup) | ❌ Không | Dùng lại Cloudinary config, thêm folder mới. |
| **Likes/Comments** | — | ❌ Không | Models mới, APIs mới, không đụng gì cũ. |
| **Share** | — | ❌ Không | Tính năng mới hoàn toàn. |
| **Bottom Navigation** | 4 tabs | ⚠️ Nhỏ | Thêm tab "Feed" thứ 5 hoặc đặt trong Home. Xem mục 9 bên dưới. |

### 2.3 Tóm tắt: Thay đổi cần thiết ở Phase 1 code khi làm Phase 2/3

```
Phase 1 Code Changes khi làm Phase 2:
├── User model: thêm 3-4 fields (height, weight, dob, goalSteps)     → 1 migration nhỏ
├── app_router.dart: thêm routes cho settings, profile edit           → additive
├── Bottom nav: Activity tab mở rộng UI (thêm goal ring)             → UI additive
└── Backend: thêm APIs mới, KHÔNG sửa APIs cũ                       → zero conflict

Phase 1 Code Changes khi làm Phase 3:
├── app_router.dart: thêm routes cho feed, post detail, comments     → additive
├── Bottom nav: có thể thêm tab 5 hoặc dùng Home tab                → nhỏ
├── Backend: thêm models + APIs hoàn toàn mới                       → zero conflict  
└── Socket.IO: thêm events mới (like notification, comment)           → additive
```

**🎯 Kết luận cuối cùng: Phase 1 có thể build thoải mái mà KHÔNG cần lo lắng Phase 2/3 phá vỡ code. Lý do:**
1. **Database**: MongoDB schema-less, thêm field/collection cực kỳ dễ
2. **API**: Versioned (`/api/v1/`), thêm endpoints mới không ảnh hưởng cũ
3. **Flutter**: Feature-based architecture, mỗi feature là folder riêng
4. **Socket.IO**: Event-based, thêm event mới không ảnh hưởng cũ

---

## 3. Kiến trúc mở rộng — Thiết kế từ Phase 1

Để tối ưu, **Phase 1 đã được thiết kế sẵn** một số pattern mở rộng:

### 3.1 Những thứ Phase 1 đã chuẩn bị sẵn cho sau này

| Đã chuẩn bị | Phục vụ Phase | Chi tiết |
|---|---|---|
| `deviceToken` trong User model | Phase 2 | Sẵn sàng cho Push Notification |
| `hourlySteps` trong step_records | Phase 2 | Sẵn data cho Charts/Statistics |
| `distance`, `calories` trong step_records | Phase 2 | Sẵn data cho Profile stats |
| Feature-based Flutter architecture | Phase 2, 3 | Thêm folder `features/social/`, `features/settings/` |
| Cloudinary config | Phase 3 | Dùng lại cho upload video/image posts |
| Socket.IO infrastructure | Phase 2, 3 | Thêm events mới cho notifications, social |
| `companyId` trên hầu hết models | Phase 2, 3 | Feed/Leaderboard scoped theo company |
| Middleware chain pattern | Phase 2, 3 | Thêm middleware mới dễ dàng |

### 3.2 Quy tắc mở rộng Phase 2, 3

```
✅ NÊN:
- Thêm collection/model MỚI
- Thêm API endpoint MỚI  
- Thêm Flutter feature folder MỚI
- Thêm fields vào model CŨ (additive)
- Thêm Socket events MỚI

❌ KHÔNG NÊN:
- Sửa response format của API cũ
- Đổi tên fields trong model cũ
- Xoá APIs đang dùng
- Thay đổi auth flow
- Sửa database indexes đang hoạt động
```

---

## 4. Phase 1 — Core Business (LOCKED)

> **Chi tiết**: Xem [PHASE1_IMPLEMENTATION_PLAN.md](PHASE1_IMPLEMENTATION_PLAN.md)

### Sprint Overview

| Sprint | Tên | Mô tả |
|---|---|---|
| Sprint 0 | Project Setup | Init dự án, config, deploy |
| Sprint 1 | Auth & Company | Đăng ký, đăng nhập, company flow |
| Sprint 2 | Super Admin Portal | Web portal phê duyệt công ty |
| Sprint 3 | Groups & Members | Tạo nhóm, quản lý thành viên, QR |
| Sprint 4 | Chat System | Chat nhóm + 1v1, hình ảnh, realtime |
| Sprint 5 | Step Counter | Foreground service, đếm bước, sync |
| Sprint 6 | Contests & Leaderboard | Cuộc thi, bảng xếp hạng |
| Sprint 7 | Integration & Polish | Kết nối, sửa bug, demo data |

### Deliverables Phase 1
- ✅ Flutter App (Android + iOS) 
- ✅ React Web Portal (Super Admin)
- ✅ Node.js Backend + Socket.IO
- ✅ MongoDB Atlas database
- ✅ Deploy trên Render + Vercel
- ✅ Demo flow 15 phút

---

## 5. Phase 2 — Personal & Analytics

> **Status**: 🟡 **~66% Done** (5/9 features completed, updated 2026-03-19)  
> **Depends on**: Phase 1 hoàn thành ✅

### 5.1 Tổng quan tính năng

| # | Tính năng | Mô tả | Complexity | Status |
|---|---|---|---|---|
| 1 | **Daily Goals** | Đặt mục tiêu bước/ngày, progress tracking | Medium | ⚠️ UI Done (GoalsPage 1016L), backend sync goal via Settings API |
| 2 | **Step Statistics** | Charts bước/ngày, tuần, tháng + Stats popup | Medium | ✅ Done (StepStatsDialog 737L + GET /steps/stats API) |
| 3 | **Profile Stats Tab** | Thống kê cá nhân trên Profile | Medium | ✅ Done (ProfilePage stats tab + ProfileRepository) |
| 4 | **Profile Edit** | Edit fullName, avatar | Low | ✅ Done (Edit dialog + PUT /auth/me) |
| 5 | **Step Progress Ring** | Animated ring trên Activity page | Low | ✅ Done (StepProgressRing widget + hourly chart) |
| 6 | **Global Leaderboard** | BXH toàn công ty (tuần/tháng), BXH nhóm | Medium | ❌ Not Started |
| 7 | **Full Profile Fields** | height, weight, dob, gender, bio | Low | ❌ Not Started (User model chưa có fields) |
| 8 | **Push Notifications** | Thông báo cuộc thi, chat, goals | Medium | ❌ Not Started (deviceToken exists nhưng chưa FCM) |
| 9 | **Settings** | Đổi mật khẩu, notification settings, units | Low | ✅ Done (UserSettings model + API + Flutter UI) |

### 5.2 Sprint Plan Phase 2

| Sprint | Tên | Tasks |
|---|---|---|
| **P2-Sprint 1** | Profile & Settings | Full profile edit, settings page, change password |
| **P2-Sprint 2** | Daily Goals | Goal setting, progress ring, congratulation animation |
| **P2-Sprint 3** | Global Leaderboard | Company-wide BXH, group BXH, time filters |
| **P2-Sprint 4** | Statistics | Charts (weekly, monthly), step history visualization |
| **P2-Sprint 5** | Push Notifications | FCM integration, notification preferences |
| **P2-Sprint 6** | Polish Phase 2 | Bug fixes, UX improvements, testing |

### 5.3 Backend — Thay đổi cần thiết

#### New Collections:
```javascript
// Collection: user_settings (MỚI)
{
  _id: ObjectId,
  userId: ObjectId,           // ref: users
  dailyGoalSteps: Number,     // default: 10000
  notifications: {
    chat: Boolean,            // default: true
    contest: Boolean,         // default: true
    dailyGoal: Boolean,       // default: true
    weeklyReport: Boolean     // default: true
  },
  units: String,              // 'metric' | 'imperial'
  createdAt: Date,
  updatedAt: Date
}
```

#### User Model Changes (additive):
```javascript
// Thêm fields MỚI vào users collection (KHÔNG sửa fields cũ):
{
  // ... existing Phase 1 fields (UNCHANGED) ...
  
  // NEW Phase 2 fields:
  height: Number,             // cm
  weight: Number,             // kg  
  dateOfBirth: Date,
  gender: String,             // 'male' | 'female' | 'other'
  bio: String                 // mô tả ngắn
}
```

#### New API Endpoints:
```
// Profile APIs (MỚI)
PUT   /api/v1/users/profile          → Update profile (fullName, avatar, height, weight, dob, gender, bio)
POST  /api/v1/users/avatar           → Upload avatar

// Settings APIs (MỚI)  
GET   /api/v1/settings               → Get user settings
PUT   /api/v1/settings               → Update settings (goals, notifications, units)

// Goals APIs (MỚI)
GET   /api/v1/goals/today            → Get today's goal + progress
GET   /api/v1/goals/history          → Goal completion history

// Global Leaderboard APIs (MỚI)
GET   /api/v1/leaderboard/company?period=week|month    → BXH toàn công ty
GET   /api/v1/leaderboard/group/:groupId?period=week   → BXH nhóm

// Statistics APIs (MỚI)
GET   /api/v1/stats/steps?range=week|month|year   → Step statistics with aggregation
GET   /api/v1/stats/summary                        → Overall summary (total steps, avg, streaks)
```

### 5.4 Flutter — Thay đổi cần thiết

```
Thêm features MỚI:
├── lib/features/settings/       → Settings feature (NEW folder)
├── lib/features/goals/          → Daily goals feature (NEW folder)
├── lib/features/leaderboard/    → Global leaderboard (NEW folder)
├── lib/features/statistics/     → Charts & stats (NEW folder)

Mở rộng features CŨ:
├── lib/features/profile/        → Thêm edit pages, stats display
└── lib/features/step_tracker/   → Thêm goal progress ring

KHÔNG sửa:
├── lib/features/auth/           → UNCHANGED
├── lib/features/chat/           → UNCHANGED
├── lib/features/group/          → UNCHANGED
└── lib/features/contest/        → UNCHANGED
```

---

## 6. Phase 3 — Social Platform

> **Status**: Chưa lock in, có thể thay đổi  
> **Depends on**: Phase 1 + Phase 2 hoàn thành

### 6.1 Tổng quan tính năng

| # | Tính năng | Mô tả | Complexity |
|---|---|---|---|
| 1 | **Post Creation** | Đăng bài text + hình ảnh | Medium |
| 2 | **Video Posts** | Đăng video ngắn (< 60s) | High |
| 3 | **Feed** | News feed trong công ty | Medium |
| 4 | **Likes** | Like ❤️ bài viết | Low |
| 5 | **Comments** | Comment bài viết | Medium |
| 6 | **Share** | Share bài viết / kết quả cuộc thi | Medium |

### 6.2 Sprint Plan Phase 3

| Sprint | Tên | Tasks |
|---|---|---|
| **P3-Sprint 1** | Post & Feed Backend | Post model, Feed API, pagination |
| **P3-Sprint 2** | Post UI | Create post, feed page, image posts |
| **P3-Sprint 3** | Likes & Comments | Like/unlike, comment CRUD, realtime |
| **P3-Sprint 4** | Video Posts | Video upload, compression, player |
| **P3-Sprint 5** | Share & Discovery | Share post, share contest results |
| **P3-Sprint 6** | Polish Phase 3 | Bug fixes, performance, testing |

### 6.3 Backend — Thay đổi cần thiết

#### New Collections (100% MỚI):
```javascript
// Collection: posts (MỚI)
{
  _id: ObjectId,
  authorId: ObjectId,         // ref: users
  companyId: ObjectId,        // ref: companies
  groupId: ObjectId,          // ref: groups (optional, nếu post trong nhóm)
  type: String,               // 'text' | 'image' | 'video' | 'contest_share'
  content: String,            // text content
  media: [{
    type: String,             // 'image' | 'video'
    url: String,              // Cloudinary URL
    thumbnail: String         // thumbnail cho video
  }],
  likesCount: Number,         // cached count
  commentsCount: Number,      // cached count
  sharedPostId: ObjectId,     // ref: posts (nếu share)
  sharedContestId: ObjectId,  // ref: contests (nếu share kết quả)
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}

// Collection: likes (MỚI)
{
  _id: ObjectId, 
  userId: ObjectId,
  postId: ObjectId,
  createdAt: Date
}
// Compound index: { userId: 1, postId: 1 } unique

// Collection: comments (MỚI)
{
  _id: ObjectId,
  postId: ObjectId,
  authorId: ObjectId,
  content: String,
  parentId: ObjectId,         // ref: comments (reply)
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

#### New API Endpoints (100% MỚI):
```
// Post APIs
POST  /api/v1/posts                    → Create post
GET   /api/v1/posts/feed               → Get feed (company-scoped, paginated)
GET   /api/v1/posts/feed/group/:id     → Get group feed
GET   /api/v1/posts/:id                → Get post detail
PUT   /api/v1/posts/:id                → Update post (author only)
DELETE /api/v1/posts/:id               → Delete post (author or admin)
POST  /api/v1/posts/:id/media          → Upload media (image/video)

// Like APIs
POST  /api/v1/posts/:id/like           → Like / Unlike (toggle)
GET   /api/v1/posts/:id/likes          → Get likes list

// Comment APIs
POST  /api/v1/posts/:id/comments       → Create comment
GET   /api/v1/posts/:id/comments       → Get comments (paginated)
PUT   /api/v1/comments/:id             → Edit comment
DELETE /api/v1/comments/:id            → Delete comment

// Share APIs
POST  /api/v1/posts/:id/share          → Share post
POST  /api/v1/contests/:id/share       → Share contest result as post
```

### 6.4 Flutter — Thay đổi cần thiết

```
Thêm features MỚI:
├── lib/features/feed/           → Feed page, post list (NEW folder)
├── lib/features/post/           → Create/detail post (NEW folder)
├── lib/features/comments/       → Comments feature (NEW folder)

Navigation change:
└── Bottom nav: thêm tab "Feed" (5 tabs total)
    hoặc: tab "Home" chứa feed, tab "Activity" cho step tracker

KHÔNG sửa:
├── lib/features/auth/           → UNCHANGED
├── lib/features/chat/           → UNCHANGED  
├── lib/features/group/          → UNCHANGED
├── lib/features/contest/        → UNCHANGED
├── lib/features/step_tracker/   → UNCHANGED
├── lib/features/profile/        → UNCHANGED (Phase 2)
├── lib/features/settings/       → UNCHANGED (Phase 2)
└── lib/features/goals/          → UNCHANGED (Phase 2)
```

### 6.5 Socket Events (MỚI, additive)
```
// Thêm events mới (KHÔNG sửa events cũ):
'social:new_like'       → { postId, userId, likesCount }
'social:new_comment'    → { postId, comment }
'social:new_post'       → { post }  (cho feed realtime)
```

---

## 7. Database Schema Evolution

### Tổng quan thay đổi qua 3 phases

```
Phase 1 (Build)              Phase 2 (Extend)           Phase 3 (Add New)
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ users            │──→ │ users + fields   │    │ (unchanged)      │
│ companies        │    │ (unchanged)      │    │ (unchanged)      │
│ groups           │    │ (unchanged)      │    │ (unchanged)      │
│ conversations    │    │ (unchanged)      │    │ (unchanged)      │
│ messages         │    │ (unchanged)      │    │ (unchanged)      │
│ contests         │    │ (unchanged)      │    │ (unchanged)      │
│ step_records     │    │ (unchanged)      │    │ (unchanged)      │
│ contest_leader   │    │ (unchanged)      │    │ (unchanged)      │
│   boards         │    │                  │    │                  │
│                  │    │ + user_settings  │    │ + posts          │
│                  │    │   (NEW)          │    │ + likes   (NEW)  │
│                  │    │                  │    │ + comments (NEW) │
└──────────────────┘    └──────────────────┘    └──────────────────┘

Collections modified:  0                1 (add fields)         0
Collections added:     8 (new)          1 (new)                3 (new)
Collections deleted:   0                0                      0
```

### Migration Strategy

```
Phase 1 → Phase 2:
  mongoose script: thêm default values cho new fields
  db.users.updateMany({}, { $set: { height: null, weight: null, dateOfBirth: null, gender: null, bio: '' } })
  → Zero downtime, backward compatible

Phase 2 → Phase 3:
  Không cần migration — chỉ tạo collections mới
  → Zero downtime, zero risk
```

---

## 8. API Evolution

### Endpoint Count theo Phase

| Phase | New Endpoints | Modified Endpoints | Total |
|---|---|---|---|
| Phase 1 | ~35 | 0 | ~35 |
| Phase 2 | ~12 | 0 | ~47 |
| Phase 3 | ~15 | 0 | ~62 |

### Versioning Strategy

```
Phase 1: /api/v1/auth/*, /api/v1/groups/*, /api/v1/chat/*, ...
Phase 2: /api/v1/settings/*, /api/v1/goals/*, /api/v1/leaderboard/*, ...  (CÙNG v1)
Phase 3: /api/v1/posts/*, /api/v1/comments/*, ...  (CÙNG v1)

→ Tất cả cùng v1 vì KHÔNG có breaking changes.
→ Chỉ bump lên v2 nếu có thay đổi response format (rất unlikely).
```

---

## 9. Navigation Evolution

### Bottom Navigation qua 3 Phases

```
Phase 1 (4 tabs):
┌──────────┬──────────┬──────────┬──────────┐
│ 🏃 Home   │ 👥 Groups │ 💬 Chat  │ 👤 Profile│
│ (Activity)│          │          │ (basic)  │
└──────────┴──────────┴──────────┴──────────┘

Phase 2 (4 tabs — UNCHANGED layout):
┌──────────┬──────────┬──────────┬──────────┐
│ 🏃 Home   │ 👥 Groups │ 💬 Chat  │ 👤 Profile│
│ + Goals  │          │          │ + Edit   │
│ + Stats  │          │          │ + Setting│
└──────────┴──────────┴──────────┴──────────┘
(Home tab mở rộng: goal ring + stats. Profile mở rộng: edit + settings)

Phase 3 — Option A (5 tabs):
┌────────┬────────┬────────┬────────┬────────┐
│ 🏃 Home │ 📱 Feed│ 👥 Group│ 💬 Chat│ 👤 Prof│
└────────┴────────┴────────┴────────┴────────┘

Phase 3 — Option B (4 tabs, Feed inside Home — ĐỀ XUẤT ✅):
┌──────────┬──────────┬──────────┬──────────┐
│ 🏠 Home   │ 👥 Groups │ 💬 Chat  │ 👤 Profile│
│ Tab: Act │          │          │          │
│ Tab: Feed│          │          │          │
└──────────┴──────────┴──────────┴──────────┘
(Home page có 2 tab nội bộ: Activity + Feed → giữ 4 bottom tabs)
```

**Đề xuất Option B**: Giữ nguyên 4 bottom tabs từ đầu đến cuối. Phase 3 chỉ thêm sub-tab trong Home → **ZERO navigation breaking change**.

### Cách chuẩn bị từ Phase 1

```dart
// app_router.dart — Phase 1
// Thiết kế ShellRoute cho bottom nav
// Dùng StatefulShellRoute → dễ thêm/sửa tabs sau

ShellRoute(
  builder: (context, state, child) => HomePage(child: child),
  routes: [
    GoRoute(path: '/home/activity', ...),   // Tab 1
    GoRoute(path: '/home/groups', ...),     // Tab 2
    GoRoute(path: '/home/chat', ...),       // Tab 3
    GoRoute(path: '/home/profile', ...),    // Tab 4
  ],
)

// Phase 2: thêm sub-routes cho /home/activity (goals, stats)
// Phase 3: thêm /home/feed hoặc sub-tab trong /home/activity
// → KHÔNG cần sửa ShellRoute structure
```

---

## 📄 File Structure — Documents

```
docs/
├── PROJECT_DOCUMENT.md              → Tổng quan kỹ thuật (all phases)
├── MASTER_PLAN.md                   → Plan tổng quan 3 phases (file này)
├── PHASE1_IMPLEMENTATION_PLAN.md    → Chi tiết implementation Phase 1
├── PHASE2_IMPLEMENTATION_PLAN.md    → (Tạo sau khi Phase 1 xong)
└── PHASE3_IMPLEMENTATION_PLAN.md    → (Tạo sau khi Phase 2 xong)
```

---

> **Phase 1 → Build thoải mái, không lo Phase 2/3 phá vỡ.**  
> **Phase 2/3 chỉ thêm mới, không sửa đổi Phase 1.**  
> **MongoDB + Feature-based architecture = mở rộng dễ dàng.**
