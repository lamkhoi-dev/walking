import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../contest/data/models/contest_model.dart';
import '../../../contest/data/repositories/contest_repository.dart';

/// Achievement picker bottom sheet for selecting a contest to share in a post.
class AchievementPicker extends StatefulWidget {
  final ContestRepository contestRepository;
  final String currentUserId;

  const AchievementPicker({
    super.key,
    required this.contestRepository,
    required this.currentUserId,
  });

  @override
  State<AchievementPicker> createState() => _AchievementPickerState();
}

class _AchievementPickerState extends State<AchievementPicker> {
  bool _isLoading = true;
  List<ContestWithRank> _contests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContests();
  }

  Future<void> _loadContests() async {
    try {
      final allContests = await widget.contestRepository.getContests();

      // Filter active/completed contests where user is participant
      final relevant = allContests.where((c) =>
          (c.status == 'active' || c.status == 'completed') &&
          c.participants.any((p) => p.id == widget.currentUserId));

      final contestsWithRank = <ContestWithRank>[];

      for (final contest in relevant) {
        try {
          final leaderboard = await widget.contestRepository.getLeaderboard(contest.id);
          final myEntry = leaderboard.where(
            (e) => e.userId == widget.currentUserId,
          ).firstOrNull;

          contestsWithRank.add(ContestWithRank(
            contest: contest,
            rank: myEntry?.rank ?? 0,
            totalSteps: myEntry?.totalSteps ?? 0,
            totalParticipants: leaderboard.length,
          ));
        } catch (_) {
          contestsWithRank.add(ContestWithRank(
            contest: contest,
            rank: 0,
            totalSteps: 0,
            totalParticipants: contest.participants.length,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _contests = contestsWithRank;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: AppColors.warning, size: 22),
                SizedBox(width: 8),
                Text(
                  'Chia sẻ thành tích',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Chọn cuộc thi để chia sẻ thành tích của bạn',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Content
          Flexible(child: _buildContent()),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadContests();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'Chưa có cuộc thi nào',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tham gia cuộc thi để chia sẻ thành tích!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _contests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _contests[index];
        return _buildContestCard(item);
      },
    );
  }

  Widget _buildContestCard(ContestWithRank item) {
    final contest = item.contest;
    final isActive = contest.status == 'active';
    final rankText = item.rank > 0 ? '#${item.rank}' : '—';
    final stepsText = _formatSteps(item.totalSteps);

    // Medal icon for top 3
    IconData rankIcon;
    Color rankColor;
    if (item.rank == 1) {
      rankIcon = Icons.emoji_events_rounded;
      rankColor = const Color(0xFFFFD700);
    } else if (item.rank == 2) {
      rankIcon = Icons.emoji_events_rounded;
      rankColor = const Color(0xFFC0C0C0);
    } else if (item.rank == 3) {
      rankIcon = Icons.emoji_events_rounded;
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankIcon = Icons.leaderboard_rounded;
      rankColor = AppColors.primary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(rankIcon, size: 20, color: rankColor),
                    Text(
                      rankText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: rankColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Contest info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contest.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isActive ? 'Đang diễn ra' : 'Đã kết thúc',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.success : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_walk_rounded,
                            size: 14,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '$stepsText bước',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people_rounded,
                            size: 14,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${item.totalParticipants} người',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps < 1000) return steps.toString();
    if (steps < 10000) return '${(steps / 1000).toStringAsFixed(1)}K';
    return '${(steps / 1000).toStringAsFixed(0)}K';
  }
}

/// Model to hold contest info + user's rank
class ContestWithRank {
  final ContestModel contest;
  final int rank;
  final int totalSteps;
  final int totalParticipants;

  ContestWithRank({
    required this.contest,
    required this.rank,
    required this.totalSteps,
    required this.totalParticipants,
  });
}
