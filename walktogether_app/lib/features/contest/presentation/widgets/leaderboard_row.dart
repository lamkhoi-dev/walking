import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/leaderboard_entry_model.dart';

/// A single row in the leaderboard list (rank 4+)
class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final bool isCurrentUser;

  const LeaderboardRow({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary, width: 1.5)
            : Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCurrentUser ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            backgroundImage: entry.avatar != null
                ? NetworkImage(entry.avatar!)
                : null,
            child: entry.avatar == null
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrentUser ? AppColors.primary : AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Hôm nay: ${_formatNumber(entry.todaySteps)} bước',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Total steps / Display steps
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(entry.displaySteps),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? AppColors.primary : AppColors.textMain,
                ),
              ),
              Text(
                'bước',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
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
