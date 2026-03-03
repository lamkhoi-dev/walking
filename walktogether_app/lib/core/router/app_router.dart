import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/pending_approval_page.dart';
import '../../features/auth/presentation/pages/rejected_page.dart';
import '../../features/auth/presentation/pages/suspended_page.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/group/data/repositories/group_repository.dart';
// GroupListBloc is provided at app level in main.dart
import '../../features/group/presentation/bloc/group_detail_bloc.dart';
import '../../features/group/presentation/bloc/group_search_bloc.dart';
import '../../features/group/presentation/pages/group_list_page.dart';
import '../../features/group/presentation/pages/group_detail_page.dart';
import '../../features/group/presentation/pages/create_group_page.dart';
import '../../features/group/presentation/pages/group_search_page.dart';
import '../../features/group/presentation/pages/group_qr_page.dart';
import '../../features/group/presentation/pages/qr_scanner_page.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/contest/data/repositories/contest_repository.dart';
import '../../features/contest/presentation/pages/contest_list_page.dart';
import '../../features/contest/presentation/pages/create_contest_page.dart';
import '../../features/contest/presentation/pages/contest_detail_page.dart';
import '../../features/contest/presentation/pages/leaderboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/step_tracker/presentation/pages/activity_page.dart';

/// Listenable that bridges AuthBloc state changes to GoRouter refresh
class AuthChangeNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _companyStatus;

  bool get isLoggedIn => _isLoggedIn;
  String? get companyStatus => _companyStatus;

  void update({required bool isLoggedIn, String? companyStatus}) {
    if (_isLoggedIn != isLoggedIn || _companyStatus != companyStatus) {
      _isLoggedIn = isLoggedIn;
      _companyStatus = companyStatus;
      notifyListeners();
    }
  }
}

/// GoRouter configuration with auth guard
class AppRouter {
  final AuthChangeNotifier authNotifier;

  AppRouter({required this.authNotifier});

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn = authNotifier.isLoggedIn;
      final companyStatus = authNotifier.companyStatus;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/';

      // Not logged in → go to welcome
      if (!loggedIn) {
        return loggingIn ? null : '/';
      }

      // Logged in but company pending
      if (companyStatus == 'pending') {
        if (state.matchedLocation == '/pending-approval') return null;
        return '/pending-approval';
      }

      // Logged in but company rejected
      if (companyStatus == 'rejected') {
        if (state.matchedLocation == '/rejected') return null;
        return '/rejected';
      }

      // Logged in but company suspended
      if (companyStatus == 'suspended') {
        if (state.matchedLocation == '/suspended') return null;
        return '/suspended';
      }

      // Logged in and on login page → go to home
      if (loggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/pending-approval',
        name: 'pending-approval',
        builder: (context, state) => const PendingApprovalPage(),
      ),
      GoRoute(
        path: '/rejected',
        name: 'rejected',
        builder: (context, state) => const RejectedPage(),
      ),
      GoRoute(
        path: '/suspended',
        name: 'suspended',
        builder: (context, state) => const SuspendedPage(),
      ),

      // ===== MAIN APP (with bottom nav) =====
      ShellRoute(
        builder: (context, state, child) => HomeShellPage(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const ActivityPage(),
          ),
          GoRoute(
            path: '/groups',
            name: 'groups',
            builder: (context, state) => const GroupListPage(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatListPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // ===== CHAT SUB-ROUTES (outside ShellRoute → no bottom nav) =====
      GoRoute(
        path: '/chat/:id',
        name: 'chat-detail',
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          final title = state.uri.queryParameters['title'];
          return BlocProvider(
            create: (_) => ChatBloc(
              repository: context.read<ChatRepository>(),
            ),
            child: ChatPage(
              conversationId: conversationId,
              title: title,
            ),
          );
        },
      ),

      // ===== GROUP SUB-ROUTES (outside ShellRoute → no bottom nav) =====
      GoRoute(
        path: '/groups/qr-scanner',
        name: 'qr-scanner',
        builder: (context, state) => const QRScannerPage(),
      ),
      GoRoute(
        path: '/groups/search',
        name: 'group-search',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => GroupSearchBloc(
              repository: context.read<GroupRepository>(),
            ),
            child: const GroupSearchPage(),
          );
        },
      ),
      GoRoute(
        path: '/groups/create',
        name: 'group-create',
        builder: (context, state) {
          return CreateGroupPage(
            repository: context.read<GroupRepository>(),
          );
        },
      ),
      GoRoute(
        path: '/groups/:id',
        name: 'group-detail',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => GroupDetailBloc(
              repository: context.read<GroupRepository>(),
            ),
            child: GroupDetailPage(groupId: groupId),
          );
        },
      ),
      GoRoute(
        path: '/groups/:id/qr',
        name: 'group-qr',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          final groupName = state.uri.queryParameters['name'] ?? 'Nhóm';
          return GroupQRPage(groupId: groupId, groupName: groupName);
        },
      ),

      // ===== CONTEST ROUTES (outside ShellRoute → no bottom nav) =====
      GoRoute(
        path: '/contests/group/:groupId',
        name: 'contest-list',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final groupName = state.uri.queryParameters['name'] ?? 'Nhóm';
          return ContestListPage(groupId: groupId, groupName: groupName);
        },
      ),
      GoRoute(
        path: '/contests/create/:groupId',
        name: 'contest-create',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final groupName = state.uri.queryParameters['name'] ?? 'Nhóm';
          return RepositoryProvider.value(
            value: context.read<ContestRepository>(),
            child: CreateContestPage(groupId: groupId, groupName: groupName),
          );
        },
      ),
      GoRoute(
        path: '/contests/:id',
        name: 'contest-detail',
        builder: (context, state) {
          final contestId = state.pathParameters['id']!;
          return ContestDetailPage(contestId: contestId);
        },
      ),
      GoRoute(
        path: '/contests/:id/leaderboard',
        name: 'contest-leaderboard',
        builder: (context, state) {
          final contestId = state.pathParameters['id']!;
          final name = state.uri.queryParameters['name'] ?? 'Bảng xếp hạng';
          return LeaderboardPage(contestId: contestId, contestName: name);
        },
      ),
    ],
  );
}
