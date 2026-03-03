import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/repositories/contest_repository.dart';
import '../bloc/leaderboard_bloc.dart';
import '../widgets/podium_widget.dart';
import '../widgets/leaderboard_row.dart';

/// Full-screen leaderboard page for a contest
class LeaderboardPage extends StatelessWidget {
  final String contestId;
  final String contestName;

  const LeaderboardPage({
    super.key,
    required this.contestId,
    required this.contestName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => LeaderboardBloc(
        repository: ctx.read<ContestRepository>(),
        socketService: SocketService(),
      )..add(LeaderboardLoadRequested(contestId)),
      child: _LeaderboardView(
        contestId: contestId,
        contestName: contestName,
      ),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  final String contestId;
  final String contestName;

  const _LeaderboardView({
    required this.contestId,
    required this.contestName,
  });

  String? _currentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(contestName),
      ),
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) {
          if (state is LeaderboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LeaderboardError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<LeaderboardBloc>()
                        .add(LeaderboardLoadRequested(contestId)),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is LeaderboardLoaded) {
            if (state.entries.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Chưa có dữ liệu bảng xếp hạng',
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<LeaderboardBloc>()
                    .add(const LeaderboardRefreshRequested());
              },
              child: CustomScrollView(
                slivers: [
                  // Podium (top 3)
                  SliverToBoxAdapter(
                    child: PodiumWidget(
                      topThree: state.podium,
                      currentUserId: currentUserId,
                    ),
                  ),

                  // Divider
                  if (state.rest.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1),
                      ),
                    ),

                  // Remaining ranks
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => LeaderboardRow(
                        entry: state.rest[index],
                        isCurrentUser: state.rest[index].userId == currentUserId,
                      ),
                      childCount: state.rest.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
