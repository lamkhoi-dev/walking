import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/repositories/contest_repository.dart';
import '../bloc/contest_list_bloc.dart';
import '../widgets/contest_card.dart';

/// Page showing list of contests for a group
class ContestListPage extends StatelessWidget {
  final String groupId;
  final String groupName;

  const ContestListPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContestListBloc(
        repository: context.read<ContestRepository>(),
      )..add(ContestListLoadRequested(groupId: groupId)),
      child: _ContestListView(
        groupId: groupId,
        groupName: groupName,
      ),
    );
  }
}

class _ContestListView extends StatelessWidget {
  final String groupId;
  final String groupName;

  const _ContestListView({
    required this.groupId,
    required this.groupName,
  });

  bool _isAdmin(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.role == 'company_admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Cuộc thi - $groupName'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push(
                  '/contests/create/$groupId?name=${Uri.encodeComponent(groupName)}',
                );
                if (result == true && context.mounted) {
                  context
                      .read<ContestListBloc>()
                      .add(ContestListRefreshRequested(groupId: groupId));
                }
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tạo cuộc thi',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: BlocBuilder<ContestListBloc, ContestListState>(
        builder: (context, state) {
          if (state is ContestListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ContestListError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ContestListBloc>()
                          .add(ContestListLoadRequested(groupId: groupId));
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is ContestListLoaded) {
            if (state.contests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có cuộc thi nào',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tạo cuộc thi đầu tiên cho nhóm!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ContestListBloc>()
                    .add(ContestListRefreshRequested(groupId: groupId));
              },
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                children: [
                  // Active contest section
                  if (state.activeContest != null) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        '🔥 ĐANG DIỄN RA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ContestCard(
                      contest: state.activeContest!,
                      onTap: () => context.push(
                        '/contests/${state.activeContest!.id}',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Upcoming section
                  if (state.upcomingContests.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        '📅 SẮP DIỄN RA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...state.upcomingContests.map(
                      (c) => ContestCard(
                        contest: c,
                        onTap: () => context.push('/contests/${c.id}'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Past section
                  if (state.pastContests.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        '📋 ĐÃ KẾT THÚC',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...state.pastContests.map(
                      (c) => ContestCard(
                        contest: c,
                        onTap: () => context.push('/contests/${c.id}'),
                      ),
                    ),
                  ],
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
