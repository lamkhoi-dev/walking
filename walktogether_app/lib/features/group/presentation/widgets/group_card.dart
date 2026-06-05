import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/group_model.dart';

/// Card widget to display a group in the list
class GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Group avatar
              AvatarWidget(
                imageUrl: group.avatar,
                name: group.name,
                size: 52,
              ),
              const SizedBox(width: 12),

              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + member count
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: AppTextStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.lastMessage != null)
                          Text(
                            _formatTime(group.lastMessage!.createdAt),
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Last message or description
                    if (group.lastMessage != null)
                      Text(
                        group.lastMessage!.senderName != null
                            ? '${group.lastMessage!.senderName}: ${group.lastMessage!.content}'
                            : group.lastMessage!.content,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (group.description != null && group.description!.isNotEmpty)
                      Text(
                        group.description!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'group.no_messages_group'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Member count
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'group.n_members'.tr(namedArgs: {'n': '${group.totalMembers}'}),
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'common.time_just_now'.tr();
    if (diff.inHours < 1) return 'common.time_minutes'.tr(namedArgs: {'n': '${diff.inMinutes}'});
    if (diff.inDays < 1) return 'common.time_hours'.tr(namedArgs: {'n': '${diff.inHours}'});
    if (diff.inDays < 7) return 'common.time_days'.tr(namedArgs: {'n': '${diff.inDays}'});
    return '${dateTime.day}/${dateTime.month}';
  }
}
