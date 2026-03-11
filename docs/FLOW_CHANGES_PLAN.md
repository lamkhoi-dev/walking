# RUNLY - Kế hoạch thay đổi Flow & Rebranding

> **Ngày tạo:** 2026-03-11  
> **Trạng thái:** Chờ duyệt trước khi implement  

---

## Mục lục

1. [Tổng quan thay đổi](#1-tổng-quan-thay-đổi)
2. [TASK 1: Auto-start Step Tracking](#2-task-1-auto-start-step-tracking)
3. [TASK 2: Đổi flow đăng ký — bỏ bắt buộc mã công ty](#3-task-2-đổi-flow-đăng-ký--bỏ-bắt-buộc-mã-công-ty)
4. [TASK 3: Gộp Nhóm vào Chat (2 tabs)](#4-task-3-gộp-nhóm-vào-chat-2-tabs)
5. [TASK 4: Đổi tên app & logo sang Runly](#5-task-4-đổi-tên-app--logo-sang-runly)
6. [Thứ tự thực hiện](#6-thứ-tự-thực-hiện)
7. [Danh sách file bị ảnh hưởng](#7-danh-sách-file-bị-ảnh-hưởng)

---

## 1. Tổng quan thay đổi

| # | Thay đổi | Loại | Ảnh hưởng |
|---|----------|------|-----------|
| 1 | Auto-start step tracking khi mở app | Bug fix | Flutter only |
| 2 | Bỏ bắt buộc mã công ty khi đăng ký user | Flow change | Backend + Flutter |
| 3 | Gộp Nhóm vào tab Chat (2 sub-tabs) | UI restructure | Flutter only |
| 4 | Đổi tên & logo → Runly | Branding | Flutter + Android + iOS + Web |

---

## 2. TASK 1: Auto-start Step Tracking

### Vấn đề hiện tại
- Step tracking **chỉ bắt đầu** khi user vào `ActivityPage` (tab Home) và BLoC nhận event `StepTrackerStartRequested`
- Nếu user login xong mà chưa vào tab Home → **không tracking**
- Nếu user bấm "Tạm ngưng" rồi "Tiếp tục" → mới bắt đầu tracking lại

### Root cause
```
main.dart → tạo StepTrackerBloc (StepTrackerInitial state)
         → KHÔNG fire StepTrackerStartRequested
         
ActivityPage.initState() → fire StepTrackerStartRequested (DUY NHẤT nơi bắt đầu)
```

### Giải pháp

**Tự động start tracking sau khi login thành công:**

#### File: `walktogether_app/lib/main.dart`
- Trong `_AppViewState`, khi `AuthAuthenticated` → dispatch `StepTrackerStartRequested` ngay
- Cụ thể: trong `BlocListener<AuthBloc, AuthState>`, sau `StepCounterService().switchUser(state.user.id)`:
  ```dart
  // Auto-start step tracking
  context.read<StepTrackerBloc>().add(StepTrackerStartRequested());
  ```

#### File: `walktogether_app/lib/features/step_tracker/presentation/pages/activity_page.dart`
- Xóa logic auto-start trong `initState()` (tránh start 2 lần)
- Giữ lại hiển thị UI, pause/resume button

#### File: `walktogether_app/lib/features/step_tracker/presentation/bloc/step_tracker_bloc.dart`
- Trong `_onStart()`: thêm check `if (_isStarted) return;` để tránh start trùng
- Hoặc kiểm tra state không phải `StepTrackerInitial` thì skip

#### File: `walktogether_app/lib/features/home/presentation/pages/home_shell_page.dart`
- Center FAB: khi app vừa mở, tracking đã chạy → FAB hiển thị đúng trạng thái (đang tracking)
- Không cần thay đổi logic FAB (nó đã đọc từ BLoC state)

### Kết quả mong đợi
- User login → tracking bắt đầu ngay lập tức
- User mở bất kỳ tab nào → bước chân đã được đếm
- Foreground notification hiện ngay sau login
- Nút pause/resume vẫn hoạt động bình thường

---

## 3. TASK 2: Đổi flow đăng ký — bỏ bắt buộc mã công ty

### Flow cũ
```
User đăng ký → nhập mã công ty (BẮT BUỘC) → gắn vào company
Admin đăng ký company trên web → SuperAdmin duyệt → tạo mã → share mã cho nhân viên
Admin tạo nhóm → chọn thành viên trong company
```

### Flow mới
```
User đăng ký → KHÔNG cần mã công ty → tài khoản tự do (như Facebook)
Company là OPTIONAL → user tự chọn sau trong Profile
Admin đăng ký company trên web → SuperAdmin duyệt → giữ mã company (tạm thời)
Admin tạo nhóm → chỉ có admin là thành viên → share QR cho người khác tham gia
```

### Thay đổi Backend

#### File: `server/src/services/auth.service.js` → `registerUser()`
**Hiện tại:**
```js
// companyCode BẮT BUỘC
const company = await Company.findOne({ code: companyCode.toUpperCase() });
if (!company) throw new Error('Mã công ty không tồn tại');
if (company.status !== 'approved') throw new Error('Công ty chưa được phê duyệt');

const user = await User.create({
  ...fields,
  role: 'member',
  companyId: company._id,
  companyCode: company.code,
});
```

**Sau khi sửa:**
```js
// companyCode OPTIONAL
let company = null;
if (companyCode) {
  company = await Company.findOne({ code: companyCode.toUpperCase() });
  if (!company) throw new Error('Mã công ty không tồn tại');
  if (company.status !== 'approved') throw new Error('Công ty chưa được phê duyệt');
}

const user = await User.create({
  ...fields,
  role: 'member',
  companyId: company?._id || undefined,
  companyCode: company?.code || undefined,
});

// Chỉ tăng totalMembers nếu có company
if (company) {
  await Company.findByIdAndUpdate(company._id, { $inc: { totalMembers: 1 } });
}
```

#### File: `server/src/validators/auth.validator.js`
- Bỏ `companyCode` khỏi required fields trong register validation
- Chuyển thành optional field

#### File: `server/src/models/User.js`
- `companyId`: đã optional (không có required) → OK
- `companyCode`: đã optional → OK
- **Không cần thay đổi schema**

#### File: `server/src/services/group.service.js` → `createGroup()`
**Hiện tại:** Validate members phải cùng company
**Sau khi sửa:**
- Admin tạo nhóm → chỉ admin là member duy nhất ban đầu
- Bỏ validation `companyId` khi add members (vì user có thể không thuộc company nào)
- Thêm cơ chế join group via QR (đã có sẵn `joinByQR`)

#### File: `server/src/services/group.service.js` → `addMembers()`
- Bỏ check `companyId` match khi add member
- Cho phép bất kỳ user active nào join group

#### File: `server/src/middleware/companyStatus.js`
- Hiện tại middleware check company approved trước khi cho dùng app
- **Cần sửa:** Cho phép user không có company vẫn dùng app bình thường
- Chỉ check company status nếu user CÓ companyId

### Thay đổi Flutter App

#### File: `walktogether_app/lib/features/auth/presentation/pages/register_page.dart`
- **Xóa** field `_companyCodeController` và UI nhập mã công ty
- Hoặc chuyển thành optional field (có nút "Có mã công ty?" expand)
- Bỏ validation 6 ký tự bắt buộc

#### File: `walktogether_app/lib/features/auth/presentation/bloc/auth_event.dart` → `AuthRegisterRequested`
- `companyCode` → optional (String? companyCode)

#### File: `walktogether_app/lib/features/auth/presentation/bloc/auth_bloc.dart` → `_onAuthRegisterRequested`
- Truyền `companyCode` chỉ khi có giá trị

#### File: `walktogether_app/lib/features/auth/data/models/register_request.dart`
- `companyCode` → nullable, không gửi nếu null

#### File: `walktogether_app/lib/core/router/app_router.dart` → redirect logic
**Hiện tại:** user pending company → redirect `/pending-approval`
**Sau khi sửa:** 
- User KHÔNG có company → cho vào app bình thường (`/home`)
- User CÓ company pending → vẫn redirect `/pending-approval` (trường hợp company_admin)
- Logic: chỉ check pending/rejected/suspended nếu user.role == 'company_admin'

#### File: `walktogether_app/lib/features/auth/presentation/pages/pending_approval_page.dart`
- Chỉ áp dụng cho `company_admin` role
- User thường không bao giờ thấy trang này

#### File: `walktogether_app/lib/features/profile/presentation/pages/profile_page.dart`
- Hiển thị company info là optional section
- Thêm nút "Tham gia công ty" nếu chưa có company (nhập mã hoặc scan QR)

### Thay đổi Web Admin
- **Không cần thay đổi** — flow đăng ký company và duyệt giữ nguyên

---

## 4. TASK 3: Gộp Nhóm vào Chat (2 tabs)

### Cấu trúc hiện tại
```
Bottom Nav: [Hoạt động] [Nhóm] [FAB] [Chat] [Hồ sơ]
                          ↓              ↓
                   GroupListPage    ChatListPage
```

### Cấu trúc mới
```
Bottom Nav: [Hoạt động] [Chat] [FAB] [Hồ sơ]
                          ↓
                   ChatTabsPage
                   ├── Tab 1: "Tin nhắn" (conversations type='direct')
                   └── Tab 2: "Nhóm" (conversations type='group' + group management)
```

### Thay đổi chi tiết

#### File MỚI: `walktogether_app/lib/features/chat/presentation/pages/chat_tabs_page.dart`
- `StatefulWidget` với `TabController` (2 tabs)
- **Tab 1 "Tin nhắn":** Filter conversations `type == 'direct'` từ ConversationListBloc
  - Dùng lại `ConversationTile` widget hiện có
  - AppBar action: nút tạo tin nhắn mới (search user -> create direct conversation)
- **Tab 2 "Nhóm":** Hiển thị groups từ GroupListBloc
  - Dùng lại `GroupCard` widget hiện có
  - AppBar actions: search group, scan QR, create group (admin only)
  - Tap group → vào chat nhóm (`/chat/:conversationId`)
  - Long press / menu → xem chi tiết nhóm (`/groups/:id`)

#### File: `walktogether_app/lib/features/chat/presentation/pages/chat_list_page.dart`
- **Giữ nguyên** hoặc refactor thành widget con (DirectMessagesTab)
- Chỉ hiển thị conversations type='direct'

#### File: `walktogether_app/lib/features/group/presentation/pages/group_list_page.dart`
- **Giữ nguyên** code nhưng embed vào Tab 2 thay vì standalone page
- Hoặc refactor thành widget con (GroupsTab)

#### File: `walktogether_app/lib/features/home/presentation/pages/home_shell_page.dart`
**Hiện tại:** 5 items (Home, Groups, FAB, Chat, Profile)
**Sau khi sửa:** 4 items (Home, Chat, FAB, Profile)
```dart
// Xóa _NavItem "Nhóm" (index 1)
// Đổi index mapping:
//   0 → /home (Hoạt động)
//   1 → /chat (Chat - bao gồm cả nhóm)
//   FAB ở giữa
//   2 → /profile (Hồ sơ)
```

**_currentIndex() mapping mới:**
```dart
int _currentIndex(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;
  if (location.startsWith('/chat')) return 1;
  if (location.startsWith('/profile')) return 2;
  return 0; // /home
}
```

**Unread badge:** gộp cả direct + group unread vào icon Chat

#### File: `walktogether_app/lib/core/router/app_router.dart`
**ShellRoute thay đổi:**
```dart
ShellRoute(
  builder: (context, state, child) => HomeShellPage(child: child),
  routes: [
    GoRoute(path: '/home', ...),
    // Xóa: GoRoute(path: '/groups', ...) 
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatTabsPage(), // MỚI
    ),
    GoRoute(path: '/profile', ...),
  ],
),
```

**Group sub-routes:** giữ nguyên (vẫn ngoài ShellRoute, không bottom nav)

### UI Design cho ChatTabsPage

```
┌──────────────────────────────────┐
│  Chat                     [🔍]  │
├─────────────┬────────────────────┤
│  Tin nhắn   │      Nhóm         │  ← TabBar
├─────────────┴────────────────────┤
│                                  │
│  Tab 1: Danh sách DM            │
│  ┌──────────────────────────┐   │
│  │ 👤 Nguyễn Văn A          │   │
│  │   Xin chào!    10:30 AM │   │
│  ├──────────────────────────┤   │
│  │ 👤 Trần Thị B            │   │
│  │   Ok nhé       Hôm qua  │   │
│  └──────────────────────────┘   │
│                                  │
│  Tab 2: Danh sách Nhóm          │
│  ┌──────────────────────────┐   │
│  │ 👥 Nhóm chạy bộ buổi sáng│   │
│  │   5 thành viên   Đang... │   │
│  │   [Vào chat]  [Chi tiết] │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ 👥 Team Marketing         │   │
│  │   8 thành viên   Tin mới │   │
│  └──────────────────────────┘   │
│                                  │
│  [+ Tạo nhóm] (admin only)     │
│  [📷 Quét QR]                   │
└──────────────────────────────────┘
```

### BLoC không cần thay đổi
- `ConversationListBloc` — đã load cả direct + group conversations
- `GroupListBloc` — vẫn dùng cho tab Nhóm
- `ChatBloc` — không thay đổi
- `GroupDetailBloc` — không thay đổi

---

## 5. TASK 4: Đổi tên app & logo sang Runly

### Logo source
- File: `D:\An\Walking\Runly-03.png` (63KB, đã tồn tại)

### Sử dụng flutter_launcher_icons package

#### Bước 1: Thêm dependency
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.3
```

#### Bước 2: Tạo file config
```yaml
# walktogether_app/flutter_launcher_icons.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "../Runly-03.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "../Runly-03.png"
  windows:
    generate: false
  macos:
    generate: false
```

#### Bước 3: Run command
```bash
dart run flutter_launcher_icons
```

### Đổi tên app — Danh sách file cần sửa

| File | Thay đổi |
|------|----------|
| `walktogether_app/pubspec.yaml` | `name: walktogether_app` → giữ nguyên (Dart package name, đổi sẽ break import) |
| `walktogether_app/pubspec.yaml` | `description` → `"Runly - Đếm bước chân, chạy bộ cùng nhau"` |
| **Android** | |
| `android/app/src/main/AndroidManifest.xml` | `android:label="walktogether_app"` → `android:label="Runly"` |
| `android/app/build.gradle` | `applicationId` → `"com.runly.app"` (hoặc giữ nguyên nếu đã publish) |
| `android/app/build.gradle` | `namespace` → `"com.runly.app"` |
| **iOS** | |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` → `"Runly"` |
| `ios/Runner/Info.plist` | `CFBundleName` → `"Runly"` |
| `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` → `com.runly.app` |
| **Web** | |
| `web/index.html` | `<title>walktogether_app</title>` → `<title>Runly</title>` |
| `web/index.html` | `apple-mobile-web-app-title` → `"Runly"` |
| `web/manifest.json` | `name` + `short_name` → `"Runly"` |

### Lưu ý quan trọng
⚠️ **applicationId (Android) & PRODUCT_BUNDLE_IDENTIFIER (iOS):**
- Nếu đã publish lên Store → **KHÔNG ĐỔI** (sẽ thành app mới)
- Nếu chưa publish → đổi sang `com.runly.app`
- **Khuyến nghị:** Hỏi trước khi đổi applicationId

⚠️ **pubspec.yaml `name` field:**
- Đây là Dart package name, **KHÔNG NÊN ĐỔI** vì tất cả import `package:walktogether_app/...` sẽ break
- Chỉ đổi `description`

---

## 6. Thứ tự thực hiện

```
Phase 1: Backend changes (ít rủi ro nhất)
  ├── 1.1 Sửa auth.service.js — companyCode optional
  ├── 1.2 Sửa auth.validator.js — bỏ required companyCode
  ├── 1.3 Sửa group.service.js — bỏ company validation khi add member
  └── 1.4 Sửa companyStatus middleware — cho phép user không có company

Phase 2: Flutter — Auto-start tracking (độc lập)
  ├── 2.1 Sửa main.dart — auto-start sau login
  └── 2.2 Sửa activity_page.dart — bỏ auto-start trùng

Phase 3: Flutter — Đổi registration flow
  ├── 3.1 Sửa register_page.dart — bỏ/optional company code field
  ├── 3.2 Sửa auth_event.dart — companyCode nullable
  ├── 3.3 Sửa auth_bloc.dart — handle optional companyCode
  ├── 3.4 Sửa register_request.dart — nullable companyCode
  └── 3.5 Sửa app_router.dart — redirect logic cho user không có company

Phase 4: Flutter — Gộp Group vào Chat
  ├── 4.1 Tạo ChatTabsPage (2 tabs)
  ├── 4.2 Sửa home_shell_page.dart — bỏ tab Nhóm, đổi index
  ├── 4.3 Sửa app_router.dart — cập nhật routes
  └── 4.4 Test navigation flow

Phase 5: Rebranding → Runly
  ├── 5.1 Đổi tên trong Android/iOS/Web config files
  ├── 5.2 Generate launcher icons từ Runly-03.png
  └── 5.3 Clean build & test
```

---

## 7. Danh sách file bị ảnh hưởng

### Backend (server/)
| File | Thay đổi |
|------|----------|
| `src/services/auth.service.js` | companyCode optional trong registerUser() |
| `src/validators/auth.validator.js` | Bỏ required companyCode |
| `src/services/group.service.js` | Bỏ company validation khi add members |
| `src/middleware/companyStatus.js` | Cho phép user không có company |

### Flutter App (walktogether_app/)
| File | Thay đổi |
|------|----------|
| `lib/main.dart` | Auto-start tracking sau AuthAuthenticated |
| `lib/core/router/app_router.dart` | Routes + redirect logic |
| `lib/features/step_tracker/presentation/pages/activity_page.dart` | Bỏ auto-start trùng |
| `lib/features/step_tracker/presentation/bloc/step_tracker_bloc.dart` | Guard chống start trùng |
| `lib/features/auth/presentation/pages/register_page.dart` | Bỏ/optional mã công ty |
| `lib/features/auth/presentation/bloc/auth_event.dart` | companyCode nullable |
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | Handle optional companyCode |
| `lib/features/auth/data/models/register_request.dart` | Nullable companyCode |
| `lib/features/chat/presentation/pages/chat_tabs_page.dart` | **MỚI** — 2-tab chat page |
| `lib/features/home/presentation/pages/home_shell_page.dart` | Bỏ tab Nhóm, 4 items |
| `lib/features/profile/presentation/pages/profile_page.dart` | Optional company section |
| `android/app/src/main/AndroidManifest.xml` | android:label → "Runly" |
| `android/app/build.gradle` | applicationId/namespace (nếu chưa publish) |
| `ios/Runner/Info.plist` | CFBundleName/DisplayName → "Runly" |
| `web/index.html` | title → "Runly" |
| `web/manifest.json` | name/short_name → "Runly" |

### File mới cần tạo
| File | Mô tả |
|------|-------|
| `lib/features/chat/presentation/pages/chat_tabs_page.dart` | Trang Chat với 2 tabs |
| `walktogether_app/flutter_launcher_icons.yaml` | Config generate icons |

---

## Câu hỏi cần xác nhận trước khi implement

1. **applicationId Android & Bundle ID iOS:** Đổi sang `com.runly.app` luôn hay giữ nguyên `com.walktogether.walktogether_app`?
2. **Mã công ty trong đăng ký:** Ẩn hoàn toàn hay để dạng optional (có nút "Tôi có mã công ty")?
3. **User chưa có company:** Có thể tham gia nhóm của công ty khác không? (Hiện tại group gắn companyId)
4. **Tab Nhóm trong Chat:** Khi tap nhóm → vào thẳng chat nhóm hay vào trang chi tiết nhóm?
5. **Center FAB:** Giữ nguyên nút Start/Stop tracking ở giữa bottom nav hay bỏ (vì đã auto-start)?
