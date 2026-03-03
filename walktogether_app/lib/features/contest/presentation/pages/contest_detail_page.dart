import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/models/contest_model.dart';
import '../../data/repositories/contest_repository.dart';
import '../bloc/contest_detail_bloc.dart';
import '../bloc/leaderboard_bloc.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/podium_widget.dart';
import '../widgets/leaderboard_row.dart';

/// Contest detail page showing info + embedded leaderboard
class ContestDetailPage extends StatelessWidget {
  final String contestId;

  const ContestDetailPage({
    super.key,
    required this.contestId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => ContestDetailBloc(
            repository: ctx.read<ContestRepository>(),
          )..add(ContestDetailLoadRequested(contestId)),
        ),
        BlocProvider(
          create: (ctx) => LeaderboardBloc(
            repository: ctx.read<ContestRepository>(),
            socketService: SocketService(),
          )..add(LeaderboardLoadRequested(contestId)),
        ),
      ],
      child: _ContestDetailView(contestId: contestId),
    );
  }
}

class _ContestDetailView extends StatelessWidget {
  final String contestId;
  const _ContestDetailView({required this.contestId});

  String? _currentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return null;
  }

  bool _isAdmin(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.role == 'company_admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContestDetailBloc, ContestDetailState>(
      listener: (context, state) {
        if (state is ContestDetailCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy cuộc thi'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true);
        }
        if (state is ContestDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết cuộc thi'),
          actions: [
            BlocBuilder<ContestDetailBloc, ContestDetailState>(
              builder: (context, state) {
                if (state is ContestDetailLoaded &&
                    state.contest.isCancellable &&
                    _isAdmin(context)) {
                  return IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                    tooltip: 'Hủy cuộc thi',
                    onPressed: () => _showCancelDialog(context, state.contest),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<ContestDetailBloc, ContestDetailState>(
          builder: (context, state) {
            if (state is ContestDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ContestDetailError) {
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
                          .read<ContestDetailBloc>()
                          .add(ContestDetailLoadRequested(contestId)),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (state is ContestDetailLoaded) {
              return _buildContent(context, state.contest);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ContestModel contest) {
    final currentUserId = _currentUserId(context);

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<ContestDetailBloc>()
            .add(ContestDetailLoadRequested(contestId));
        context
            .read<LeaderboardBloc>()
            .add(const LeaderboardRefreshRequested());
      },
      child: CustomScrollView(
        slivers: [
          // Contest Info Header
          SliverToBoxAdapter(child: _buildHeader(context, contest)),

          // Leaderboard Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.leaderboard, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Bảng xếp hạng',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const Spacer(),
                  BlocBuilder<LeaderboardBloc, LeaderboardState>(
                    builder: (context, state) {
                      if (state is LeaderboardLoaded) {
                        return Text(
                          '${state.entries.length} người chơi',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Podium
          SliverToBoxAdapter(
            child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
              builder: (context, state) {
                if (state is LeaderboardLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is LeaderboardLoaded) {
                  return PodiumWidget(
                    topThree: state.podium,
                    currentUserId: currentUserId,
                  );
                }
                if (state is LeaderboardError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(child: Text(state.message)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Remaining ranks
          BlocBuilder<LeaderboardBloc, LeaderboardState>(
            builder: (context, state) {
              if (state is LeaderboardLoaded && state.rest.isNotEmpty) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => LeaderboardRow(
                      entry: state.rest[index],
                      isCurrentUser: state.rest[index].userId == currentUserId,
                    ),
                    childCount: state.rest.length,
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ContestModel contest) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Status
          Row(
            children: [
              Expanded(
                child: Text(
                  contest.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(contest.status),
            ],
          ),

          // Description
          if (contest.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              contest.description,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Group & Creator info
          if (contest.groupName != null)
            _buildInfoRow(
              Icons.group,
              'Nhóm',
              contest.groupName!,
            ),
          if (contest.createdByName != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.person,
              'Người tạo',
              contest.createdByName!,
            ),
          ],

          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.people,
            'Số người tham gia',
            '${contest.participants.length}',
          ),

          const SizedBox(height: 12),

          // Date info
          Row(
            children: [
              Expanded(
                child: _buildDateBox(
                  'Bắt đầu',
                  contest.startDate,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateBox(
                  'Kết thúc',
                  contest.endDate,
                  AppColors.danger,
                ),
              ),
            ],
          ),

          // Countdown
          if (contest.status == 'upcoming') ...[
            const SizedBox(height: 12),
            CountdownWidget(
              targetDate: contest.startDate,
              label: 'Bắt đầu sau',
            ),
          ] else if (contest.status == 'active') ...[
            const SizedBox(height: 12),
            CountdownWidget(
              targetDate: contest.endDate,
              label: 'Kết thúc sau',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateBox(String label, DateTime date, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'active':
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        label = 'Đang diễn ra';
        break;
      case 'upcoming':
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        label = 'Sắp tới';
        break;
      case 'completed':
        bgColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue;
        label = 'Đã kết thúc';
        break;
      case 'cancelled':
        bgColor = AppColors.danger.withValues(alpha: 0.15);
        textColor = AppColors.danger;
        label = 'Đã hủy';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ContestModel contest) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy cuộc thi?'),
        content: Text(
          'Bạn có chắc muốn hủy cuộc thi "${contest.name}"?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context
                  .read<ContestDetailBloc>()
                  .add(ContestDetailCancelRequested(contest.id));
            },
            child: const Text('Hủy cuộc thi'),
          ),
        ],
      ),
    );
  }
}
