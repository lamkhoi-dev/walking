import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/leaderboard_entry_model.dart';

/// Podium widget showing top 3 participants with gold, silver, bronze
class PodiumWidget extends StatelessWidget {
  final List<LeaderboardEntryModel> topThree;
  final String? currentUserId;

  const PodiumWidget({
    super.key,
    required this.topThree,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa có dữ liệu')),
      );
    }

    // Arrange: 2nd on left, 1st in middle, 3rd on right
    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            Expanded(child: _PodiumPlace(
              entry: second,
              rank: 2,
              height: 100,
              color: const Color(0xFFA8A9AD), // Silver
              isCurrentUser: second.userId == currentUserId,
            ))
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 8),
          if (first != null)
            Expanded(child: _PodiumPlace(
              entry: first,
              rank: 1,
              height: 130,
              color: const Color(0xFFFFD700), // Gold
              isCurrentUser: first.userId == currentUserId,
            ))
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 8),
          if (third != null)
            Expanded(child: _PodiumPlace(
              entry: third,
              rank: 3,
              height: 80,
              color: const Color(0xFFCD7F32), // Bronze
              isCurrentUser: third.userId == currentUserId,
            ))
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final int rank;
  final double height;
  final Color color;
  final bool isCurrentUser;

  const _PodiumPlace({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser ? AppColors.primary : color,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 30 : 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: entry.avatar != null
                    ? NetworkImage(entry.avatar!)
                    : null,
                child: entry.avatar == null
                    ? Icon(Icons.person, size: rank == 1 ? 30 : 24)
                    : null,
              ),
            ),
            Positioned(
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          entry.fullName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
            color: isCurrentUser ? AppColors.primary : AppColors.textMain,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Steps
        Text(
          '${_formatNumber(entry.displaySteps)} bước',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        // Podium bar
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              rank == 1
                  ? '🥇'
                  : rank == 2
                      ? '🥈'
                      : '🥉',
              style: TextStyle(fontSize: rank == 1 ? 32 : 24),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
