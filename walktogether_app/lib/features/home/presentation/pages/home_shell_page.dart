import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/bloc/conversation_list_bloc.dart';
import '../../../step_tracker/presentation/bloc/step_tracker_bloc.dart';

/// Home shell page with bottom navigation bar
/// Wraps child routes: /home, /chat, /profile
class HomeShellPage extends StatelessWidget {
  final Widget child;

  const HomeShellPage({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0; // /home
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.directions_run,
                  label: 'Hoạt động',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                // Center FAB — toggle step tracking
                BlocBuilder<StepTrackerBloc, StepTrackerState>(
                  builder: (context, stepState) {
                    final isTracking = stepState is StepTrackerRunning && stepState.isTracking;
                    return _CenterFAB(
                      isTracking: isTracking,
                      onTap: () {
                        final bloc = context.read<StepTrackerBloc>();
                        if (isTracking) {
                          bloc.add(StepTrackerStopRequested());
                        } else {
                          bloc.add(StepTrackerStartRequested());
                        }
                        // Navigate to activity tab
                        if (currentIndex != 0) {
                          context.go('/home');
                        }
                      },
                    );
                  },
                ),
                // Chat badge from conversation state
                BlocBuilder<ConversationListBloc, ConversationListState>(
                  builder: (context, chatState) {
                    int unread = 0;
                    if (chatState is ConversationListLoaded) {
                      for (final c in chatState.conversations) {
                        unread += c.unreadCount;
                      }
                    } else if (chatState is ConversationListDirectCreated) {
                      for (final c in chatState.conversations) {
                        unread += c.unreadCount;
                      }
                    }
                    return _NavItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      isSelected: currentIndex == 1,
                      onTap: () => context.go('/chat'),
                      badgeCount: unread > 0 ? unread : null,
                    );
                  },
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Hồ sơ',
                  isSelected: currentIndex == 2,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFAB extends StatelessWidget {
  final VoidCallback onTap;
  final bool isTracking;

  const _CenterFAB({required this.onTap, this.isTracking = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isTracking
                ? [AppColors.danger, const Color(0xFFEF5350)]
                : [AppColors.primary, const Color(0xFF66BB6A)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 4),
          boxShadow: [
            BoxShadow(
              color: (isTracking ? AppColors.danger : AppColors.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isTracking ? Icons.stop : Icons.directions_walk,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}
