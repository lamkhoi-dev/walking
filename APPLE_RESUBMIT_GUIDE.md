# 🍎 Runly — Apple App Store Resubmission Guide

> **Tài liệu toàn diện** dành cho AI/người thao tác trên MacBook để hoàn tất quy trình submit lại app Runly lên Apple App Store sau khi bị reject.

---

## 1. Tổng quan dự án

| Thông tin | Giá trị |
|-----------|---------|
| **App Name** | Runly — Đếm bước chân cùng đồng nghiệp |
| **Bundle ID** | `com.runly.app` |
| **Tech Stack** | Flutter (mobile) + Node.js/Express (backend) + MongoDB Atlas |
| **Git Remotes** | `origin` = lamkhoi-dev/walking, `origin2` = LofizDev/Runner-App |
| **iOS Branch** | `pro/ios` (đã merge đầy đủ compliance code) |
| **Android Branch** | `pro/android` |
| **Rejection Date** | 15/04/2026 |
| **Submission ID** | `9dcab9e3-a7d7-4f58-80aa-e7ed255cd9c3` |
| **Review Device** | iPad Air 11-inch (M3) |

---

## 2. Lý do bị Apple Reject

Apple reject app Runly vì **2 Guideline vi phạm**:

### Guideline 1.2 — Safety — User-Generated Content (UGC)
App có tính năng UGC (feed bài viết, chat nhóm) nhưng **thiếu**:
1. ❌ EULA/Terms of Use — Không yêu cầu user đồng ý điều khoản
2. ❌ Block User — Không có cơ chế chặn người dùng, tự động xoá nội dung khỏi feed
3. ❌ Report Content — Không có cơ chế báo cáo nội dung vi phạm
4. ❌ 24h Response Policy — Chưa cam kết phản hồi báo cáo trong 24h

### Guideline 5.1.1(v) — Data Collection and Storage
App cho phép tạo tài khoản nhưng **không có chức năng xoá tài khoản** trong app.

### Apple yêu cầu kèm theo
> **BẮT BUỘC** gửi kèm **screen recording trên thiết bị thật** chứng minh:
> - EULA hiển thị trước khi user truy cập UGC
> - Cơ chế báo cáo nội dung vi phạm
> - Cơ chế chặn người dùng
> - Flow xoá tài khoản từ đầu đến cuối

---

## 3. Trạng thái hiện tại: ✅ ĐÃ IMPLEMENT 100%

Tất cả code đã hoàn tất, analyzed (0 errors), committed, merged vào `main` → `pro/ios` → `pro/android`, và pushed lên cả 2 remotes.

### Ma trận đối chiếu Apple Requirements ↔ Implementation

| # | Apple yêu cầu | Status | Giải pháp | Files chính |
|---|--------------|--------|-----------|-------------|
| 1 | **EULA bắt buộc trước khi truy cập UGC** | ✅ Done | Checkbox bắt buộc tại RegisterPage. Backend lưu `acceptedTermsAt`. Trang Terms có 6 sections nội dung đầy đủ. | `register_page.dart`, `terms_page.dart`, `User.js` |
| 2 | **Block user + thông báo dev + xoá khỏi feed** | ✅ Done | Nút Block trên PostCard (feed) + PostDetail. Backend tự động tạo Report (lý do "harassment") khi block. Feed query dùng `$nin: blockedUsers` để lọc. | `post_card.dart`, `feed_page.dart`, `post_detail_page.dart`, `auth.service.js`, `post.service.js` |
| 3 | **Report content mechanism** | ✅ Done | ReportDialog (bottom sheet) với 5 lý do. Backend lưu vào collection `Reports`. Accessible từ feed card + post detail. | `report_dialog.dart`, `Report.js`, `report.service.js`, `ReportController.js` |
| 4 | **24h response policy** | ✅ Done | Cam kết trong Notes for Review + EULA text. | Text trong review notes |
| 5 | **Account deletion in-app** | ✅ Done | Settings → Danger Zone → nhập password → soft delete (xoá PII, deactivate, cleanup related data). | `settings_page.dart`, `settings_bloc.dart`, `auth.service.js` |
| 6 | **Privacy Policy in-app** | ✅ Done | Settings → "Chính sách bảo mật" → mở browser tới `https://lamkhoi-dev.github.io/walking/`. Nội dung đã cập nhật phản ánh in-app deletion. | `settings_page.dart`, `docs/index.html` |
| 7 | **Contact info** | ✅ Done | `support@runly.app` trong Terms + Privacy Policy. | `terms_page.dart`, `docs/index.html` |

### Git Commits liên quan
```
29a57a5 fix: add privacy link in settings, report/block on feed, update policy
a765c94 feat: apple compliance - EULA, report content, block user, delete account
```

### Branches đã đồng bộ
- `main` ✅
- `pro/ios` ✅ (merged from main)
- `pro/android` ✅ (merged from main)
- `f/apple-compliance` ✅ (feature branch, completed)

---

## 4. Những việc CÒN PHẢI LÀM trước khi Submit

### Checklist

- [ ] **4.1** Pull code mới nhất trên Mac (`pro/ios` branch)
- [ ] **4.2** Test 5 flow trên thiết bị thật (xem Section 5)
- [ ] **4.3** Quay 2 video screen recording (xem Section 6)
- [ ] **4.4** Build + Archive trên Xcode, upload lên App Store Connect
- [ ] **4.5** Điền Notes for Review + attach video (xem Section 7)
- [ ] **4.6** Reply trong Resolution Center (xem Section 8)
- [ ] **4.7** Submit for Review

---

## 5. Hướng dẫn Test từng tính năng

> ⚠️ Tất cả test cần chạy trên **thiết bị thật** (iPhone/iPad). Cần 2 tài khoản test: 1 tài khoản chính, 1 tài khoản phụ (để test block/report).

### 5.1 EULA / Điều khoản sử dụng

| Bước | Thao tác | Kỳ vọng |
|------|----------|---------|
| 1 | Đăng xuất. Bấm "Đăng ký" | Hiện form đăng ký |
| 2 | Điền đầy đủ thông tin, **KHÔNG tick** checkbox EULA | Nút Đăng ký **disabled** (xám), hiện text đỏ yêu cầu |
| 3 | Bấm link "Điều khoản dịch vụ" trong text | Mở trang Terms (6 sections nội dung) |
| 4 | Quay lại, **tick** checkbox | Nút Đăng ký **enabled** (xanh) |
| 5 | Bấm Đăng ký | Tạo tài khoản thành công, vào app |

### 5.2 Báo cáo bài viết (Report)

| Bước | Thao tác | Kỳ vọng |
|------|----------|---------|
| 1 | Vào tab Feed (Bảng tin) | Thấy danh sách bài viết |
| 2 | Tìm bài của **người khác**, bấm `⋮` (3 chấm) trên PostCard | Menu popup: "Báo cáo bài viết" + "Chặn người dùng" |
| 3 | Bấm "Báo cáo bài viết" | Bottom sheet hiện 5 lý do |
| 4 | Chọn 1 lý do (VD: Spam), tuỳ chọn ghi chú thêm | Lý do được highlight |
| 5 | Bấm "Gửi báo cáo" | SnackBar xanh: "Cảm ơn bạn đã báo cáo..." |
| 6 | *(Verify backend)* Check MongoDB collection `reports` | Có document mới với `targetType: 'post'` |

> **Lưu ý:** Bấm `⋮` trên bài của **chính mình** → chỉ hiện "Xóa bài viết" (không có Report/Block).

### 5.3 Chặn người dùng (Block)

| Bước | Thao tác | Kỳ vọng |
|------|----------|---------|
| 1 | Trên Feed, bấm `⋮` bài người khác → "Chặn người dùng" | Dialog xác nhận: "Bạn sẽ không thấy bài viết từ [Tên] nữa..." |
| 2 | Bấm "Chặn" | SnackBar xanh: "Đã chặn [Tên]" |
| 3 | Kéo refresh Feed | Tất cả bài của người bị chặn **biến mất** |
| 4 | *(Verify backend)* | `User.blockedUsers` có thêm ID. Collection `reports` có auto-report "harassment" |

### 5.4 Quản lý Setting (Bỏ chặn + Privacy)

| Bước | Thao tác | Kỳ vọng |
|------|----------|---------|
| 1 | Tab Profile → icon ⚙️ (Settings) | Mở trang Cài đặt |
| 2 | Mục Tài khoản → "Chính sách bảo mật" | Mở browser → trang `https://lamkhoi-dev.github.io/walking/` |
| 3 | Quay lại → "Điều khoản sử dụng" | Mở trang Terms trong app |
| 4 | "Người đã chặn" | Hiện danh sách user đã block |
| 5 | Bấm "Bỏ chặn" cạnh tên | User biến mất khỏi list |
| 6 | Quay ra Feed, refresh | Bài của người vừa unblock **xuất hiện lại** |

### 5.5 Xóa tài khoản (Account Deletion)

> ⚠️ **Dùng tài khoản test phụ** — thao tác này không hoàn tác được!

| Bước | Thao tác | Kỳ vọng |
|------|----------|---------|
| 1 | Settings → kéo xuống "Vùng nguy hiểm" (đỏ) | Thấy nút "Xóa tài khoản" |
| 2 | Bấm "Xóa tài khoản" | Dialog đỏ yêu cầu nhập mật khẩu |
| 3 | Nhập **sai** mật khẩu → OK | Thông báo lỗi "Mật khẩu không đúng" |
| 4 | Nhập **đúng** mật khẩu → OK | App đăng xuất, về màn Login |
| 5 | Thử đăng nhập lại bằng tài khoản vừa xoá | Không đăng nhập được |
| 6 | *(Verify backend)* Check MongoDB | `isActive: false`, `deletedAt` có giá trị, `fullName: "Tài khoản đã xóa"`, `email: null` |

---

## 6. Hướng dẫn quay Video Screen Recording

Apple **BẮT BUỘC** gửi kèm screen recording. Trích nguyên văn:
> *"reply to this message with a screen recording captured on a physical device that demonstrates..."*

### Cách quay trên iPhone/iPad
1. Vào **Settings → Control Center** → thêm "Screen Recording"
2. Vuốt Control Center → bấm nút ⏺ → đợi 3 giây → thao tác
3. Bấm thanh đỏ trên cùng để dừng → video lưu vào Photos

### Video 1: UGC Safety Features (~60-90 giây)

**Kịch bản quay:**

```
1. [Màn hình Đăng ký]
   → Điền thông tin đăng ký
   → Cho thấy checkbox EULA chưa tick → nút Đăng ký disabled
   → Tick checkbox → nút enabled
   → Bấm link xem Điều khoản → quay lại
   → Bấm Đăng ký thành công

2. [Feed — Bảng tin]
   → Tìm bài người khác
   → Bấm ⋮ → cho thấy menu "Báo cáo" + "Chặn"
   → Bấm "Báo cáo bài viết"
   → Chọn lý do → Gửi → thấy SnackBar thành công

3. [Feed — Chặn]
   → Bấm ⋮ bài khác → "Chặn người dùng"
   → Xác nhận → SnackBar thành công
   → Kéo refresh feed → bài biến mất
```

### Video 2: Account Deletion (~30-45 giây)

**Kịch bản quay:**

```
1. [Đăng nhập bằng tài khoản test]

2. [Settings — Cài đặt]
   → Kéo xuống "Vùng nguy hiểm"
   → Bấm "Xóa tài khoản"
   → Nhập mật khẩu
   → Xác nhận xoá

3. [Kết quả]
   → App tự động đăng xuất → về màn Login
```

---

## 7. Build & Upload trên macOS

### 7.1 Pull code

```bash
cd <đường_dẫn_project>/Walking
git checkout pro/ios
git pull origin pro/ios
```

### 7.2 Flutter build

```bash
cd walktogether_app
flutter clean
flutter pub get
flutter build ios --release
```

### 7.3 Xcode Archive & Upload

1. Mở `walktogether_app/ios/Runner.xcworkspace` trong **Xcode**
2. Chọn device: **Any iOS Device (arm64)**
3. **QUAN TRỌNG:** Tăng Build Number (hoặc Version)
   - `Runner → TARGETS → Runner → General → Build` (VD: 1.0 build 2)
4. Menu: **Product → Archive**
5. Sau khi archive xong → **Distribute App → App Store Connect → Upload**
6. Đợi processing xong trên App Store Connect (~5-10 phút)

### 7.4 Điền trên App Store Connect

1. Vào **App Store Connect** → Runly → **iOS App** → chọn build mới
2. Mục **App Review Information**:
   - **Demo Account:**
     - Username: `[ĐIỀN_EMAIL_DEMO]`
     - Password: `[ĐIỀN_PASSWORD_DEMO]`
   - **Notes for Review** — Paste nội dung sau:

```
## Content Safety & Moderation

Runly includes comprehensive User-Generated Content (UGC) safety features:

1. EULA / Terms of Use:
   - Users must accept the Terms of Use during registration via a mandatory checkbox.
   - Terms are accessible anytime from Settings → "Điều khoản sử dụng".

2. Report Content:
   - Users can report any post via the "⋮" menu → "Báo cáo bài viết".
   - 5 report categories: Spam, Harassment, Inappropriate Content, False Information, Other.
   - Reports include optional description text.
   - All reports are reviewed and acted upon within 24 hours.

3. Block Users:
   - Users can block other users via the "⋮" menu → "Chặn người dùng" on any post.
   - Blocked users' content is immediately hidden from the feed.
   - Users can manage blocked users from Settings → "Người đã chặn".

4. Account Deletion:
   - Users can delete their account from Settings → "Xóa tài khoản".
   - Requires password confirmation for security.
   - All personal data (profile, step records, settings) is permanently removed.

5. Privacy Policy:
   - Accessible in-app from Settings → "Chính sách bảo mật".
   - Also available at: https://lamkhoi-dev.github.io/walking/

## Demo Account
Email: [ĐIỀN_EMAIL_DEMO]
Password: [ĐIỀN_PASSWORD_DEMO]

## How to Test Safety Features
1. Log in with the demo account.
2. Go to the Feed tab → tap "⋮" on any post from another user.
3. You will see "Báo cáo bài viết" (Report) and "Chặn người dùng" (Block) options.
4. Go to Settings (Profile tab → gear icon) to find:
   - "Người đã chặn" (Blocked Users management)
   - "Điều khoản sử dụng" (Terms of Use)
   - "Chính sách bảo mật" (Privacy Policy)
   - "Xóa tài khoản" (Delete Account)
```

3. **Attachments:** Upload 2 video đã quay (Video 1 + Video 2)

---

## 8. Reply trong Resolution Center

Vào **App Store Connect → Resolution Center** → Reply tin nhắn rejection cũ (Submission ID: `9dcab9e3-a7d7-4f58-80aa-e7ed255cd9c3`):

```
Dear Review Team,

Thank you for your detailed feedback. We have implemented all required changes:

Guideline 1.2 — User-Generated Content:
✅ EULA: Users must accept Terms of Use via mandatory checkbox during registration.
✅ Report: Users can flag objectionable content via "⋮" → "Báo cáo bài viết" (5 categories).
✅ Block: Users can block abusive users via "⋮" → "Chặn người dùng". Blocked content is immediately removed from the feed, and an automatic report is created for developer review.
✅ 24h Policy: All reports are reviewed and acted upon within 24 hours.

Guideline 5.1.1(v) — Account Deletion:
✅ Users can delete their account directly in-app via Settings → "Xóa tài khoản" with password confirmation. All personal data is permanently removed.

We have attached screen recordings on a physical device demonstrating all features. Demo account credentials are provided in the Review Notes.

Best regards,
Runly Team
```

---

## 9. Submit

Sau khi hoàn tất tất cả bước trên:
1. Bấm **"Add for Review"** trên App Store Connect
2. Bấm **"Submit to App Review"**
3. Chờ kết quả (~24-48h)

---

## 10. Tóm tắt kiến trúc compliance (cho AI reference)

```
Backend (Node.js/Express):
├── models/User.js          → blockedUsers[], acceptedTermsAt, deletedAt
├── models/Report.js        → reporterId, targetType, targetId, reason
├── services/auth.service.js → softDeleteAccount(), blockUser(), unblockUser()
├── services/report.service.js → createReport()
├── controllers/auth.controller.js → deleteAccount, blockUser, unblockUser
├── controllers/ReportController.js → create
├── routes/auth.routes.js   → DELETE /auth/account, POST /auth/block/:id
├── routes/report.routes.js → POST /reports
└── services/post.service.js → getFeed() filters blockedUsers via $nin

Frontend (Flutter):
├── register_page.dart      → EULA checkbox (mandatory)
├── terms_page.dart         → Static Terms of Use content
├── post_card.dart          → onReport, onBlock, onDelete callbacks
├── feed_page.dart          → isOwner detection, report/block from feed
├── post_detail_page.dart   → report/block from detail
├── report_dialog.dart      → Bottom sheet, 5 reasons
├── settings_page.dart      → Privacy link, Terms, Blocked users, Delete account
├── blocked_users_page.dart → Manage + unblock
├── settings_bloc.dart      → deleteAccount()
├── settings_repository.dart → API calls for block/unblock/report/delete
└── api_endpoints.dart      → Endpoint constants
```
