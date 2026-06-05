import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
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
import '../../features/group/presentation/pages/group_detail_page.dart';
import '../../features/group/presentation/pages/create_group_page.dart';
import '../../features/group/presentation/pages/group_search_page.dart';
import '../../features/group/presentation/pages/group_qr_page.dart';
import '../../features/group/presentation/pages/qr_scanner_page.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/pages/chat_tabs_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/contest/data/repositories/contest_repository.dart';
import '../../features/contest/presentation/pages/contest_list_page.dart';
import '../../features/contest/presentation/pages/create_contest_page.dart';
import '../../features/contest/presentation/pages/contest_detail_page.dart';
import '../../features/contest/presentation/pages/leaderboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/step_tracker/presentation/pages/activity_page.dart';
import '../../features/step_tracker/presentation/pages/goals_page.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/terms_page.dart';
import '../../features/settings/presentation/pages/blocked_users_page.dart';
import '../../features/feed/data/repositories/feed_repository.dart';
import '../../features/feed/presentation/bloc/feed_bloc.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/feed/presentation/pages/create_post_page.dart';
import '../../features/feed/presentation/pages/post_detail_page.dart';
import '../../features/feed/presentation/bloc/post_detail_bloc.dart';
import '../../features/friend/presentation/pages/user_profile_page.dart';
import '../../features/friend/presentation/pages/friends_page.dart';
import '../../features/friend/presentation/pages/friend_search_page.dart';
import '../../core/network/dio_client.dart';

/// Listenable that bridges AuthBloc state changes to GoRouter refresh
class AuthChangeNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _companyStatus;
  bool _isConnectingServer = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get companyStatus => _companyStatus;
  bool get isConnectingServer => _isConnectingServer;

  void update({required bool isLoggedIn, String? companyStatus, bool isConnectingServer = false}) {
    if (_isLoggedIn != isLoggedIn || _companyStatus != companyStatus || _isConnectingServer != isConnectingServer) {
      _isLoggedIn = isLoggedIn;
      _companyStatus = companyStatus;
      _isConnectingServer = isConnectingServer;
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
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn = authNotifier.isLoggedIn;
      final companyStatus = authNotifier.companyStatus;
      final isConnecting = authNotifier.isConnectingServer;
      final currentPath = state.matchedLocation;
      final isAuthPage = currentPath == '/login' ||
          currentPath == '/register' ||
          currentPath == '/' ||
          currentPath == '/connecting';

      // Server cold start in progress — stay on connecting page
      if (isConnecting) {
        if (currentPath == '/connecting') return null;
        return '/connecting';
      }

      // Not logged in → go to welcome (if not already on auth pages)
      if (!loggedIn) {
        if (currentPath == '/' || currentPath == '/login' || currentPath == '/register') {
          return null;
        }
        return '/';
      }

      // === LOGGED IN ===

      // Company pending
      if (companyStatus == 'pending') {
        if (currentPath == '/pending-approval') return null;
        return '/pending-approval';
      }

      // Company rejected
      if (companyStatus == 'rejected') {
        if (currentPath == '/rejected') return null;
        return '/rejected';
      }

      // Company suspended
      if (companyStatus == 'suspended') {
        if (currentPath == '/suspended') return null;
        return '/suspended';
      }

      // Logged in with approved company — redirect auth pages to home
      if (isAuthPage) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/connecting',
        name: 'connecting',
        builder: (context, state) => const _ServerConnectingPage(),
      ),
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
            path: '/feed',
            name: 'feed',
            builder: (context, state) {
              return BlocProvider(
                create: (_) => FeedBloc(
                  repository: context.read<FeedRepository>(),
                ),
                child: const FeedPage(),
              );
            },
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatTabsPage(),
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
          final groupId = state.uri.queryParameters['groupId'];
          return BlocProvider(
            create: (_) => ChatBloc(
              repository: context.read<ChatRepository>(),
            ),
            child: ChatPage(
              conversationId: conversationId,
              title: title,
              groupId: groupId,
            ),
          );
        },
      ),

      // ===== GOALS PAGE (outside ShellRoute → no bottom nav) =====
      GoRoute(
        path: '/goals',
        name: 'goals',
        builder: (context, state) => const GoalsPage(),
      ),

      // ===== POST ROUTES (outside ShellRoute → no bottom nav) =====
      GoRoute(
        path: '/post/create',
        name: 'create-post',
        builder: (context, state) {
          return RepositoryProvider.value(
            value: context.read<FeedRepository>(),
            child: const CreatePostPage(),
          );
        },
      ),
      GoRoute(
        path: '/post/:id',
        name: 'post-detail',
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => PostDetailBloc(
              repository: context.read<FeedRepository>(),
            )..add(PostDetailLoadRequested(postId)),
            child: PostDetailPage(postId: postId),
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
          final groupName = state.uri.queryParameters['name'] ?? 'group.default_name'.tr();
          return GroupQRPage(groupId: groupId, groupName: groupName);
        },
      ),

      // ===== CONTEST ROUTES (outside ShellRoute → no bottom nav) =====
      GoRoute(
        path: '/contests/group/:groupId',
        name: 'contest-list',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final groupName = state.uri.queryParameters['name'] ?? 'group.default_name'.tr();
          final groupCompanyId = state.uri.queryParameters['companyId'];
          return ContestListPage(
            groupId: groupId,
            groupName: groupName,
            groupCompanyId: groupCompanyId,
          );
        },
      ),
      GoRoute(
        path: '/contests/create/:groupId',
        name: 'contest-create',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final groupName = state.uri.queryParameters['name'] ?? 'group.default_name'.tr();
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
          final name = state.uri.queryParameters['name'] ?? 'contest.leaderboard'.tr();
          return LeaderboardPage(contestId: contestId, contestName: name);
        },
      ),

      // ===== SETTINGS ROUTES (outside ShellRoute → no bottom nav) =====
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => SettingsCubit(
              repository: SettingsRepository(
                dio: context.read<DioClient>(),
              ),
            ),
            child: const SettingsPage(),
          );
        },
      ),
      GoRoute(
        path: '/settings/change-password',
        name: 'change-password',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => SettingsCubit(
              repository: SettingsRepository(
                dio: context.read<DioClient>(),
              ),
            ),
            child: const ChangePasswordPage(),
          );
        },
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: '/settings/blocked',
        name: 'blocked-users',
        builder: (context, state) => const BlockedUsersPage(),
      ),

      // ===== FRIEND ROUTES (outside ShellRoute → no bottom nav) =====
      GoRoute(
        path: '/user/:id',
        name: 'user-profile',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return UserProfilePage(userId: userId);
        },
      ),
      GoRoute(
        path: '/friends',
        name: 'friends',
        builder: (context, state) => const FriendsPage(),
      ),
      GoRoute(
        path: '/friends/search',
        name: 'friend-search',
        builder: (context, state) => const FriendSearchPage(),
      ),
    ],
  );
}

/// Page shown during Render server cold start
class _ServerConnectingPage extends StatelessWidget {
  const _ServerConnectingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isFailed = state is AuthConnectingFailed;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFailed) ...[
                    const SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: Color(0xFF44C548),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'common.loading_title'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'common.loading_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'common.cannot_connect'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'common.connect_failed_desc'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthCheckRequested());
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('common.retry'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF44C548),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                      child: Text(
                        'common.re_login'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
