# 📊 Database Architecture — WalkTogether / Runly

> Tài liệu mô tả cấu trúc database MongoDB và luồng data của hệ thống.

---

## Tổng quan

- **Database:** MongoDB Atlas
- **ODM:** Mongoose 8.6
- **8 Collections:** User, Company, Group, Contest, ContestLeaderboard, StepRecord, Conversation, Message

---

## 📦 Schema chi tiết

### 1. User

Thông tin người dùng & xác thực.

| Field | Type | Mô tả |
|-------|------|--------|
| `email` | String (unique, sparse) | Email đăng nhập |
| `phone` | String (unique, sparse) | SĐT đăng nhập |
| `password` | String (required, hidden) | Mật khẩu (bcrypt hash) |
| `fullName` | String (required) | Họ tên |
| `avatar` | String | URL ảnh đại diện (Cloudinary) |
| `role` | Enum | `super_admin` / `company_admin` / `member` |
| `companyId` | ObjectId → Company | Công ty thuộc về |
| `companyCode` | String | Mã công ty khi đăng ký |
| `isActive` | Boolean | Trạng thái hoạt động |
| `deviceToken` | String | Token push notification |
| `lastOnline` | Date | Lần online cuối |

> ⚠️ **User KHÔNG chứa field số bước chân.** Dữ liệu bước chân lưu trong `StepRecord`.

---

### 2. Company

Thông tin công ty với quy trình duyệt.

| Field | Type | Mô tả |
|-------|------|--------|
| `name` | String (required) | Tên công ty |
| `email` | String (required) | Email liên hệ |
| `phone` | String | SĐT |
| `address` | String | Địa chỉ |
| `description` | String | Mô tả |
| `logo` | String | URL logo |
| `code` | String (unique) | Mã công ty (tự sinh) |
| `status` | Enum | `pending` → `approved` / `rejected` / `suspended` |
| `adminId` | ObjectId → User | Tài khoản admin công ty |
| `totalMembers` | Number | Tổng số thành viên |

---

### 3. Group

Nhóm trong công ty, quản lý thành viên.

| Field | Type | Mô tả |
|-------|------|--------|
| `name` | String (required) | Tên nhóm |
| `description` | String | Mô tả nhóm |
| `avatar` | String | Ảnh đại diện nhóm |
| `companyId` | ObjectId → Company | Thuộc công ty |
| `createdBy` | ObjectId → User | Người tạo |
| `members` | [ObjectId → User] | Danh sách thành viên |
| `totalMembers` | Number | Tổng thành viên |
| `conversationId` | ObjectId → Conversation | Cuộc hội thoại nhóm |
| `isActive` | Boolean | Trạng thái |

---

### 4. Contest

Cuộc thi đếm bước trong nhóm.

| Field | Type | Mô tả |
|-------|------|--------|
| `name` | String (required) | Tên cuộc thi |
| `description` | String | Mô tả |
| `groupId` | ObjectId → Group | Nhóm tổ chức |
| `companyId` | ObjectId → Company | Thuộc công ty |
| `createdBy` | ObjectId → User | Người tạo |
| `startDate` | Date | Ngày bắt đầu |
| `endDate` | Date | Ngày kết thúc |
| `status` | Enum | `upcoming` / `active` / `completed` / `cancelled` |
| `participants` | [ObjectId → User] | Danh sách tham gia |

---

### 5. ContestLeaderboard

Bảng xếp hạng bước chân trong cuộc thi.

| Field | Type | Mô tả |
|-------|------|--------|
| `contestId` | ObjectId → Contest | Cuộc thi |
| `userId` | ObjectId → User | Người tham gia |
| `totalSteps` | Number | Tổng bước chân |
| `dailySteps` | Map<String, Number> | Bước theo ngày `{"2026-03-17": 8520}` |
| `rank` | Number | Xếp hạng |

> Unique index: `(contestId, userId)` — mỗi user chỉ có 1 record/cuộc thi

---

### 6. StepRecord ⭐

**Dữ liệu bước chân hàng ngày** — collection quan trọng nhất cho tính năng đếm bước.

| Field | Type | Mô tả |
|-------|------|--------|
| `userId` | ObjectId → User | Người dùng |
| `companyId` | ObjectId → Company | Thuộc công ty |
| `date` | String | Ngày `"YYYY-MM-DD"` |
| `steps` | Number (min: 0) | Tổng bước trong ngày |
| `distance` | Number | Quãng đường (mét) — tự tính: `steps × 0.762` |
| `calories` | Number | Calo tiêu hao (kcal) — tự tính: `steps × 0.04` |
| `hourlySteps` | Map<String, Number> | Bước theo giờ `{"08": 520, "09": 1200}` |
| `syncedAt` | Date | Thời điểm sync cuối |

> Unique index: `(userId, date)` — **mỗi user chỉ có 1 record/ngày** (upsert khi sync)

---

### 7. Conversation

Cuộc hội thoại (nhắn tin trực tiếp hoặc nhóm).

| Field | Type | Mô tả |
|-------|------|--------|
| `type` | Enum | `group` / `direct` |
| `groupId` | ObjectId → Group | Nhóm (nếu type = group) |
| `participants` | [ObjectId → User] | Thành viên tham gia |
| `lastMessage` | Object | Tin nhắn mới nhất (preview) |
| `companyId` | ObjectId → Company | Thuộc công ty |
| `isActive` | Boolean | Trạng thái |

---

### 8. Message

Tin nhắn trong cuộc hội thoại.

| Field | Type | Mô tả |
|-------|------|--------|
| `conversationId` | ObjectId → Conversation | Thuộc cuộc hội thoại |
| `senderId` | ObjectId → User (nullable) | Người gửi (null = system) |
| `type` | Enum | `text` / `image` / `system` |
| `content` | String | Nội dung tin nhắn |
| `imageUrl` | String | URL ảnh (nếu type = image) |
| `readBy` | [ObjectId → User] | Danh sách đã đọc |

---

## 🔗 Sơ đồ quan hệ

```
Company (1) ──────┬──── (N) User
                  │
                  ├──── (N) Group ──── (N) Members (User)
                  │         │
                  │         ├──── (1) Conversation ──── (N) Message
                  │         │
                  │         └──── (N) Contest ──── (N) Participants (User)
                  │                    │
                  │                    └──── (N) ContestLeaderboard
                  │
                  └──── (N) StepRecord

User (1) ────┬──── (N) StepRecord (1 record/ngày)
             ├──── (N) ContestLeaderboard
             ├──── (N) Message (sender)
             └──── (N) Conversation (participant)
```

---

## 🔄 Luồng Data bước chân

### Sync lên server (App → Server)

```
📱 Điện thoại
│
│  Pedometer sensor → StepCounterService
│  (lưu Hive local: todaySteps, hourlySteps, goalHistory)
│
▼
🔄 StepSyncService (tự động mỗi N giây)
│
│  Ưu tiên: Socket.IO emit('steps:sync', data)
│  Fallback: POST /api/v1/steps/sync
│  Offline:  Queue vào Hive, gửi khi có mạng
│
│  Payload: { date: "2026-03-17", steps: 8520, hourlySteps: {...} }
│
▼
🖥️ Server (step.service.js)
│
│  Upsert StepRecord (userId + date = unique key)
│  Tự tính: distance = steps × 0.762m
│           calories = steps × 0.04 kcal
│
▼
🗄️ MongoDB — StepRecord collection
```

### Fetch từ server (Server → App)

```
🗄️ MongoDB — StepRecord collection
│
│  GET /steps/today    → record hôm nay của user (req.user._id)
│  GET /steps/history  → tất cả records theo date range
│  GET /steps/stats    → tổng hợp: today/week/month
│
▼
📱 App (khi cần khôi phục data — vd: reinstall)
│
│  StepTrackerBloc._restoreFromServer()
│  → gọi GET /steps/history (không giới hạn ngày)
│  → server trả về CHỈ data của user đang login
│  → populate vào Hive goalHistory
│  → GoalsPage hiển thị đúng data lịch sử
```

### Tại sao không lưu steps trong User?

| Lưu trong User | Lưu trong StepRecord (hiện tại) |
|----------------|--------------------------------|
| ❌ Chỉ lưu được tổng, mất lịch sử | ✅ Lưu chi tiết từng ngày |
| ❌ Không có hourlySteps | ✅ Breakdown theo giờ |
| ❌ Khó query theo date range | ✅ Query linh hoạt (tuần/tháng/năm) |
| ❌ Không hỗ trợ leaderboard theo ngày | ✅ Aggregation pipeline dễ dàng |
| ❌ User document phình to | ✅ Tách biệt, scale tốt |

---

## 📱 Local Storage (Hive — trên điện thoại)

Mỗi user có 1 Hive box riêng: `step_counter_{userId}`

| Key | Type | Mô tả |
|-----|------|--------|
| `today_steps` | int | Bước hôm nay (từ sensor) |
| `baseline_steps` | int | Baseline sensor lúc bắt đầu ngày |
| `last_sensor_steps` | int | Giá trị sensor gần nhất |
| `tracking_date` | String | Ngày đang tracking (reset lúc nửa đêm) |
| `hourly_steps` | Map | Bước theo giờ hôm nay |
| `is_tracking` | bool | Đang tracking hay không |
| `daily_goal` | int | Mục tiêu bước/ngày (default: 10000) |
| `goal_history` | Map | Lịch sử: `{"2026-03-17": {steps, goal, achieved}}` |
| `current_streak` | int | Chuỗi ngày liên tiếp đạt mục tiêu |

> ⚠️ Hive bị xoá khi gỡ app. Sau reinstall, `goal_history` sẽ được khôi phục từ server qua `GET /steps/history`.
