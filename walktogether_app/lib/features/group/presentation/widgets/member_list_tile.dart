import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/member_model.dart';

/// List tile widget for displaying a member
class MemberListTile extends StatelessWidget {
  final MemberModel member;
  final bool isCreator;
  final bool showRemoveButton;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const MemberListTile({
    super.key,
    required this.member,
    this.isCreator = false,
    this.showRemoveButton = false,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: AvatarWidget(
        imageUrl: member.avatar,
        name: member.fullName,
        size: 44,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.fullName,
              style: AppTextStyles.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCreator) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Trưởng nhóm',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (member.role == 'company_admin' && !isCreator) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Admin',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        member.email ?? member.phone ?? '',
        style: AppTextStyles.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: showRemoveButton && !isCreator
          ? IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: AppColors.danger.withValues(alpha: 0.7),
                size: 22,
              ),
              onPressed: onRemove,
              tooltip: 'Xóa thành viên',
            )
          : null,
      onTap: onTap,
    );
  }
}
