# 🎨 WalkTogether — UI/UX Prompts cho AI Stitch

> **Mục đích**: 5 prompts chính — Design System + 4 màn đại diện.  
> **Cách dùng**: Đưa lần lượt vào Stitch. Các màn còn lại tự build từ components.  
> **Platform**: Flutter Mobile App + React Web Portal

---

## 📋 Mục lục

1. [Design System & Components](#1-design-system--components)
2. [Home Screen — Step Tracker (màn chính app)](#2-home-screen--step-tracker)
3. [Chat Room Screen (messaging UI)](#3-chat-room-screen)
4. [Contest Leaderboard Screen (ranking/gamification)](#4-contest-leaderboard-screen)
5. [Super Admin Dashboard (web portal)](#5-super-admin-dashboard)

---

## 1. Design System & Components

> **Đưa prompt này vào Stitch ĐẦU TIÊN** — thiết lập toàn bộ visual language.

```
PROMPT:

Design a complete UI Design System / Component Library for a fitness walking app called "WalkTogether". This app is for companies — employees walk together, join groups, compete in step-counting contests, and chat. Built with Flutter mobile + React web.

DESIGN TOKENS:
- Theme: Fitness, Walking, Health, Corporate wellness
- Style: Modern, Clean, Rounded corners, Soft shadows, Friendly
- Primary: #4CAF50 (Green — nature, health)
- Secondary: #2196F3 (Blue — trust, freshness)
- Accent: #FF9800 (Orange — energy, motivation)
- Background: #F5F7FA
- Card: #FFFFFF
- Text Primary: #1A1A2E
- Text Secondary: #6B7280
- Error: #EF4444
- Gold: #FFD700, Silver: #C0C0C0, Bronze: #CD7F32
- Typography: Inter or Poppins (rounded, modern)
- Border Radius: 16px cards, 12px buttons, 24px inputs
- Shadows: rgba(0,0,0,0.08) soft drop-shadow
- Icons: Outlined style (Lucide / Material Outlined)
- Spacing: 8px grid
- Gradient Primary: linear-gradient(135deg, #4CAF50, #2196F3)
- Gradient Accent: linear-gradient(135deg, #FF9800, #FF5722)
- Gradient Card: linear-gradient(135deg, #667eea, #764ba2)

SHOW ALL THESE COMPONENTS ON ONE LARGE SHEET:

1. BUTTONS (all states: default, pressed, disabled, loading):
   - Primary: Green gradient, white text, rounded 12px, height 56px, soft shadow
   - Secondary/Outlined: White bg, green border, green text
   - Danger: Red bg, white text
   - Text button: No background, green or gray text
   - Icon button: Circle 48px, with icon inside
   - FAB: Green gradient circle 56px, white icon, shadow

2. INPUT FIELDS (states: empty, focused, filled, error, disabled):
   - Text input: Rounded 24px, light gray bg (#F0F2F5), leading icon, placeholder gray
   - Focused: Green border glow
   - Error: Red border + red helper text below
   - Password: With eye toggle suffix icon
   - Search: Rounded pill shape, search icon, "Tìm kiếm..." placeholder
   - Multiline/Textarea: Rounded 16px, 3 lines

3. CARDS:
   - Default card: White, rounded 16px, soft shadow
   - Stat card: Small, icon + large number + label (used for step count, calories, distance)
   - Highlighted/Gradient card: Green→Blue or Purple→Blue gradient bg, white text
   - Info card: Light blue (#EBF5FB) bg, info icon, text
   - List card: Horizontal layout — avatar left, text center, trailing right

4. BADGES & CHIPS:
   - Status badges: Pending (orange bg), Approved (green bg), Rejected (red bg), Suspended (gray bg)
   - Role chips: Admin (gold border, crown icon), Member (blue)
   - Notification badge: Red circle, white number (for unread count)
   - Filter chips: Selectable, green when active, gray when inactive

5. AVATARS:
   - Sizes: 32px, 40px, 48px, 64px, 80px, 100px
   - Circle with border
   - With online indicator: small green dot at bottom-right
   - With role badge: gold crown for admin
   - Group avatar: 2-3 overlapping circles
   - Avatar placeholder: gray bg with person icon

6. NAVIGATION:
   - Bottom nav bar: 4 tabs (Activity, Groups, Chat, Profile)
     Active: filled green icon + green label + green pill indicator above
     Inactive: outlined gray icon + gray label
     Chat with unread red badge
   - Tab bar: Underline style with green active indicator
   - App bar: Back arrow left, title center, action icons right

7. CHAT COMPONENTS:
   - Sent message bubble: Green gradient bg, white text, rounded (TL 16, TR 4, BL 16, BR 16)
   - Received message bubble: White bg, dark text, shadow, rounded (TL 4, TR 16, BL 16, BR 16)
   - Image message: Rounded corner image in bubble
   - Message input bar: Camera icon + rounded text field + send button (green circle, white arrow)
   - Typing indicator: "typing..." with 3 animated dots
   - Time stamp: Small gray text below bubbles
   - Conversation list item: Avatar + Name + Last message + Time + Unread badge

8. LEADERBOARD / RANKING:
   - Podium top 3: Gold (#FFD700), Silver (#C0C0C0), Bronze (#CD7F32)
     Three avatar circles on podium pedestals (1st in center, taller)
     Medal icons: 🥇 🥈 🥉
   - Rank row: "#4 [Avatar] Name — 55,210 steps" with subtle border-bottom
   - Current user highlight: Light green background row
   - Circular progress ring: Large (250px), thick green gradient stroke, number in center

9. DIALOGS & OVERLAYS:
   - Confirmation dialog: Rounded 20px, icon + title + description + two buttons
   - Bottom sheet: Rounded top 24px, drag handle pill (40x4px), title + content
   - Toast/Snackbar: Success (green), Error (red), Info (blue) — rounded 12px, icon + text

10. STATES:
    - Loading: Skeleton shimmer effect (for cards, lists, text)
    - Circular spinner: Green
    - Empty state: Illustration + Title + Description + Action button
    - Error state: Red icon + message + retry button
    - Pull-to-refresh: Green indicator

11. MISCELLANEOUS:
    - Section header: Bold title left + "See all →" link right
    - Divider: Thin gray line 0.5px
    - Date separator: "— Hôm nay —" centered gray text between gray lines
    - Quick action button: Circle icon (56px) + label below, light colored bg

LAYOUT: Organize components in labeled sections on a large artboard. Clean, well-spaced, each component group clearly labeled. Show multiple states side by side.

DIMENSIONS: 1440 x 2400px artboard
```

---

## 2. Home Screen — Step Tracker

> **Màn chính của app** — hiển thị bước chân, thống kê, cuộc thi đang active. Chủ lực component: circular progress ring, stat cards, gradient header, quick actions, bottom nav.

```
PROMPT:

Design the main Home screen for a fitness walking app called "WalkTogether" in Flutter mobile. This is the primary screen — it shows daily step count and activity summary. Use the WalkTogether design system: green primary (#4CAF50), blue secondary (#2196F3), rounded 16px cards, soft shadows, Inter/Poppins font.

SCREEN DETAILS:

TOP SECTION — Gradient header (#4CAF50 → #2196F3), curved bottom edge:
- Greeting: "Xin chào, Minh! 👋" (Hello, Minh!) — white, bold, 20px
- Date: "Thứ Hai, 02/03/2026" — white, 14px
- Company badge: "Công ty ABC" — small white outlined chip

HERO ELEMENT — Large circular step counter (overlapping header + white area):
- Circular progress ring, 250px diameter
- Ring: 12px thick green gradient stroke (#4CAF50 → #2196F3), gray track behind
- Inside the ring:
  - Small walking person icon (green)
  - Large number: "8,432" — bold 48px, dark (#1A1A2E)
  - Label: "bước" — gray 16px
- Below ring: "84% mục tiêu" — green text small

3 STAT CARDS in horizontal row (below the ring, inside a white card):
| 🔥 342 cal | 📏 6.4 km | ⏱ 84 phút |
Each: small rounded card, colored icon, bold value, gray label

QUICK ACTIONS — 4 circular buttons, horizontal scroll:
- 👥 Nhóm (Groups) — light green bg
- 🏆 Cuộc thi (Contests) — light purple bg
- 💬 Chat — light blue bg
- 📊 Xếp hạng (Ranking) — light orange bg
Each: circle 56px with icon, label below, light pastel background

ACTIVE CONTEST BANNER (if any) — gradient card (purple→blue):
- "🏆 Thử thách 10K bước" — white bold
- Progress bar: "Còn 3 ngày" — thin bar showing time remaining
- "Hạng #5 · 42,310 bước" — white
- Arrow → indicating tappable

RECENT ACTIVITY:
- Section header: "Hoạt động gần đây" + "Xem tất cả →"
- 2 small list items:
  "Hôm qua: 10,234 bước ✅" — green check
  "28/02: 6,891 bước" — gray

BOTTOM NAVIGATION BAR:
4 tabs: 🏃 Hoạt động (active, green) | 👥 Nhóm | 💬 Chat [3] | 👤 Hồ sơ
Active: green filled icon + green pill indicator above + green label
Inactive: gray outlined icon + gray label. Chat has red unread badge "3".

STYLE: The circular progress ring is the visual hero — centered, prominent, motivational. The header curves down elegantly behind the ring. Everything feels energetic and health-focused. Cards have 16px radius, soft shadows. Scrollable content. Background #F5F7FA.

DIMENSIONS: 390 x 844px (iPhone 14)
```

---

## 3. Chat Room Screen

> **Messaging UI** — khác biệt hoàn toàn so với các màn khác. Component: message bubbles (sent/received), image message, input bar, typing indicator, custom app bar.

```
PROMPT:

Design a Chat Room / Messaging screen for "WalkTogether" fitness app in Flutter mobile. This is used for both group chat and 1-on-1 direct messages. Use the WalkTogether design system: green primary (#4CAF50), rounded, soft shadows, Inter/Poppins font.

SCREEN DETAILS:

CUSTOM APP BAR (white, subtle bottom shadow):
- Back arrow (left)
- Group avatar (40px circle) + Group name "Team Chạy Bộ Sáng" (bold) + "12 thành viên" (gray, small)
- For DM: Person avatar + Name + green "Online" dot
- Right: More options (⋯) icon

MESSAGE AREA — Background: #F5F7FA, full screen scrollable:

DATE SEPARATOR: "── Hôm nay ──" (gray text between thin lines, centered)

RECEIVED MESSAGES (left-aligned):
- Sender avatar (32px, left side — group chat only)
- Sender name above bubble: "Trần Thị Hoa" — colored small bold text
- Bubble: White bg, dark text, soft shadow
  Border radius: top-left 4px, top-right 16px, bottom-left 16px, bottom-right 16px
- Time: "14:30" — tiny gray below bubble

SENT MESSAGES (right-aligned):
- Bubble: Green gradient (#4CAF50 → #43A047) bg, white text
  Border radius: top-left 16px, top-right 4px, bottom-left 16px, bottom-right 16px
- Time: "14:32" — tiny gray below
- Read receipt: ✓✓ blue double-check

IMAGE MESSAGE:
- Rounded 12px image container (max 240px width)
- Inside a message bubble (no extra bg for images, just the rounded image)
- Sent: right-aligned. Received: left-aligned with avatar.

SYSTEM MESSAGE (centered):
"Minh đã tham gia nhóm" — small gray italic text, no bubble, centered

TYPING INDICATOR (bottom of messages):
- 3 small avatar circles overlapping + "đang gõ..." text with animated dots (●○○)

SHOW A NATURAL CONVERSATION with mix of:
- 2 received text messages (from different senders in group)
- 1 sent text message
- 1 received image message
- 1 sent message with read receipt
- 1 system message
- Typing indicator at bottom

INPUT BAR (fixed bottom, white bg, top shadow):
┌────────────────────────────────────────────────┐
│ [📷]  [Nhập tin nhắn...               ] [🟢➤] │
│ camera  rounded input 24px, gray bg     send   │
└────────────────────────────────────────────────┘
- Camera/photo button: gray icon, tap to upload image
- Input: Rounded 24px, #F0F2F5 bg, multiline expandable, "Nhập tin nhắn..." placeholder
- Send button: Green circle 40px, white arrow icon — only visible when input has text

STYLE: WhatsApp/Telegram inspired but more polished. Green sent, white received. Smooth rounded bubbles. Avatar visible only for received in groups. Clean, fast-feeling, modern messaging UI.

DIMENSIONS: 390 x 844px (iPhone 14)
```

---

## 4. Contest Leaderboard Screen

> **Ranking / Gamification UI** — component: podium top 3, rank list, gradient header, stat cards. Reusable cho global leaderboard sau này.

```
PROMPT:

Design a Contest Detail + Leaderboard screen for "WalkTogether" fitness app in Flutter mobile. This shows a walking contest with a live ranking of participants. Use the WalkTogether design system: green (#4CAF50), blue (#2196F3), purple gradient cards, rounded, modern.

SCREEN DETAILS:

GRADIENT HEADER (purple→blue: #667eea → #764ba2, curved bottom):
- Back arrow (white, top-left)
- Share icon (white, top-right)
- Contest name: "Thử thách 10K bước" — white, bold, 22px
- Group: "Team Chạy Bộ Sáng" — white, 14px
- Date: "02/03 — 09/03/2026" — white, 13px
- Status badge: "🟢 Đang diễn ra" — small white outlined chip

YOUR STATS CARD (white, rounded 16px, shadow, overlapping header):
┌─────────────────────────────────────────────┐
│  Hạng của bạn           Tổng bước           │
│  #5 (green, bold 36px)  42,310 (bold 36px)  │
│  ──────────────────────────────────────────  │
│  Hôm nay: +8,432 bước           📈 +12%     │
└─────────────────────────────────────────────┘

TOP 3 PODIUM (visual hero section):
Three avatar circles on podium-style pedestals:

          🥈                🥇                🥉
       [Avatar]          [Avatar]          [Avatar]
     Trần T. Hoa     Nguyễn V. Minh      Lê H. Nam
      68,201            72,432            61,892
      
- 1st place: Center, tallest pedestal, gold (#FFD700) ring around avatar, crown icon, glow effect
- 2nd place: Left, shorter pedestal, silver (#C0C0C0) ring
- 3rd place: Right, shortest, bronze (#CD7F32) ring
- Pedestals: Rounded top, colored matching medal color, subtle gradient
- Avatar size: 64px with colored border ring
- Medal emoji below avatar
- Name (bold, 14px) + Total steps (16px)

REMAINING RANKS LIST (below podium):
Section title: "Bảng xếp hạng" (Leaderboard)

Each row — horizontal, padded, separated:
#4  [Avatar 36px] Trần Văn Đức     55,210 bước   +5,100 hôm nay
#5  [Avatar 36px] Bạn              42,310 bước   +8,432 hôm nay  ← HIGHLIGHTED (light green #E8F5E9 bg)
#6  [Avatar 36px] Phạm Thị Mai     38,901 bước   +3,200 hôm nay
#7  [Avatar 36px] Hoàng Minh       35,100 bước   +4,800 hôm nay
#8  [Avatar 36px] Lê Thị Lan       31,220 bước   +2,100 hôm nay

Row details:
- Rank number (bold, left, 16px)
- Avatar (36px circle)
- Name (bold 14px)
- Total steps (bold, right area)
- Today's steps (smaller, gray, below total)
- Current user row: light green (#E8F5E9) background highlight
- Thin divider between rows

STYLE: The podium is the visual centerpiece — premium, competitive feeling with medal colors and glow. The gradient header gives a "special event" feel. The rank list is clean and scannable. Current user always highlighted. Scrollable for many participants.

DIMENSIONS: 390 x 844px (iPhone 14)
```

---

## 5. Super Admin Dashboard

> **Web portal** — layout sidebar + content. Component: sidebar nav, stat cards, data table, action buttons. Dùng lại cho Company List, Company Detail.

```
PROMPT:

Design a Super Admin Dashboard page for "WalkTogether" web portal. This is a React web app for managing companies that register on the platform. Use the WalkTogether design system: green (#4CAF50), clean, modern, Ant Design-inspired components.

SCREEN DETAILS:

SIDEBAR (left, fixed, 260px wide, dark bg #1A1A2E):
- Top: WalkTogether logo — green walking icon + "WalkTogether" text (white)
- Nav items (vertical, 48px height each):
  📊 Dashboard — ACTIVE: green left border (3px), light bg tint (#2D2D4A), white text
  🏢 Công ty (Companies) — inactive: gray text, hover: lighter bg
  👥 Người dùng (Users)
  ⚙️ Cài đặt (Settings)
- Bottom section: Avatar circle (36px) + "Super Admin" text + logout icon (right), gray border-top

MAIN CONTENT AREA (right, bg #F5F7FA, padded 32px):

TOP BAR:
- Left: "Xin chào, Admin! 👋" — bold 24px
- Right: Date "02/03/2026" + Notification bell icon with red badge "3"

4 STAT CARDS (horizontal row, equal width, 16px gap):
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ 🏢              │ │ ⏳              │ │ ✅              │ │ 👥              │
│ 24              │ │ 5               │ │ 18              │ │ 1,234           │
│ Tổng công ty    │ │ Chờ duyệt      │ │ Đã duyệt       │ │ Tổng users      │
│ +3 tuần này     │ │                  │ │                  │ │ +56 tuần này    │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
- White card, rounded 12px, soft shadow
- Left: colored icon circle (48px) — green for total, orange for pending, green for approved, blue for users
- "Chờ duyệt" card: orange accent border-left to draw attention
- Number: bold 32px. Label: gray 14px. Trend: small green +number

PENDING COMPANIES TABLE:
- Section title: "Công ty chờ phê duyệt (5)" — bold 18px + "Xem tất cả →" link (blue)
- White card, rounded 12px

TABLE:
| Tên công ty      | Email              | Admin          | Ngày ĐK    | Hành động        |
|─────────────────|───────────────────|───────────────|───────────|─────────────────|
| Công ty ABC      | info@abc.com       | Nguyễn Minh    | 01/03/2026 | [✅ Duyệt] [❌]  |
| Công ty XYZ      | hr@xyz.com         | Trần Hoa       | 28/02/2026 | [✅ Duyệt] [❌]  |
| Tech Corp        | admin@tech.com     | Lê Nam         | 27/02/2026 | [✅ Duyệt] [❌]  |

- Row hover: light blue (#F0F7FF) bg
- "Duyệt" button: small, green bg, white text
- "❌" button: small, outlined red
- Alternating row tint (very subtle)

RECENT ACTIVITY (below or right column):
- Card with timeline:
  🟢 "Đã duyệt Công ty DEF" — 1 giờ trước
  🟡 "Công ty GHI đăng ký mới" — 3 giờ trước
  🔴 "Đã từ chối Công ty JKL" — 5 giờ trước
Each: colored dot + text + time (gray)

STYLE: Clean admin dashboard. Dark sidebar contrasts with light content. Ant Design inspired — professional, data-focused but not overwhelming. The Pending card and table draw attention (orange accent). Responsive layout. Stats give quick overview.

DIMENSIONS: 1440 x 900px (desktop)
```

---

## 📝 Hướng dẫn sử dụng

### Thứ tự đưa vào Stitch:

| # | Prompt | Mục đích | Tái sử dụng cho |
|---|---|---|---|
| 1 | **Design System** | Thiết lập style toàn bộ | Tất cả màn hình |
| 2 | **Home Screen** | Màn chính app, gradient header | Welcome, Profile, Group Detail |
| 3 | **Chat Room** | Messaging UI | Chat List (dùng conversation item component) |
| 4 | **Leaderboard** | Ranking, podium, stat cards | Contest List, Group contests |
| 5 | **Admin Dashboard** | Web layout, sidebar, table | Company List, Company Detail, Login |

### Mapping — Màn còn lại tự build từ components:

| Màn hình | Lấy components từ |
|---|---|
| Welcome / Login / Register | Prompt 1 (buttons, inputs) + Prompt 2 (gradient header) |
| Pending / Rejected / Suspended | Prompt 1 (cards, badges, buttons, empty states) |
| Groups List | Prompt 1 (list cards, search, FAB, avatar) |
| Group Detail | Prompt 2 (gradient header) + Prompt 1 (tabs, list tiles) |
| Create Group / Create Contest | Prompt 1 (inputs, buttons, chips, avatars) |
| Chat List | Prompt 3 (conversation item) + Prompt 1 (tabs, badges) |
| Contest List | Prompt 4 (gradient card, stat cards) + Prompt 1 (tabs) |
| Profile | Prompt 2 (gradient header, stat row) + Prompt 1 (list tiles) |
| QR Scanner | Prompt 1 (buttons, dialogs) — camera UI custom |
| Web: Company List | Prompt 5 (sidebar, table, badges) |
| Web: Company Detail | Prompt 5 (sidebar, cards) + Prompt 1 (stat cards, badges) |
| Web: Login | Prompt 5 (layout) + Prompt 1 (inputs, buttons) |
| Web: Company Register | Prompt 5 (layout) + Prompt 1 (inputs, buttons) |

### Tips:
- Nếu Stitch chưa đúng style → paste lại Design Tokens từ Prompt 1 lên đầu
- Reference gợi ý: "Inspired by Nike Run Club + Strava + WhatsApp"
- Export assets: 1x, 2x, 3x cho Flutter
