import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/post_model.dart';
import 'package:intl/intl.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isOwnComment;
  final VoidCallback? onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    this.isOwnComment = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with gradient border
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isOwnComment
                  ? AppColors.primaryGradient
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade400],
                    ),
            ),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(1),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: comment.author.avatar != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: comment.author.avatar!,
                          fit: BoxFit.cover,
                          width: 34,
                          height: 34,
                          placeholder: (_, __) => _avatarPlaceholder(),
                          errorWidget: (_, __, ___) => _avatarPlaceholder(),
                        ),
                      )
                    : _avatarPlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Comment bubble
          Expanded(
            child: GestureDetector(
              onLongPress:
                  isOwnComment ? () => _showDeleteSheet(context) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isOwnComment
                          ? AppColors.primary.withValues(alpha: 0.07)
                          : const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isOwnComment ? 18 : 4),
                        topRight: const Radius.circular(18),
                        bottomLeft: const Radius.circular(18),
                        bottomRight: const Radius.circular(18),
                      ),
                      border: isOwnComment
                          ? Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              width: 0.5,
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author name with badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                comment.author.fullName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isOwnComment
                                      ? AppColors.primary
                                      : AppColors.textMain,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOwnComment) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Bạn',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Comment content
                        Text(
                          comment.content,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textMain,
                            letterSpacing: 0.05,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Timestamp + actions row (outside bubble)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 4),
                    child: Row(
                      children: [
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                        if (isOwnComment) ...[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(
                              width: 2.5,
                              height: 2.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showDeleteSheet(context),
                            child: Text(
                              'Xóa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    final initial = comment.author.fullName.isNotEmpty
        ? comment.author.fullName[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewPadding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  comment.content.length > 80
                      ? '${comment.content.substring(0, 80)}...'
                      : comment.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Delete action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete?.call();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text(
                          'Xóa bình luận',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Cancel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM/yy').format(dateTime);
  }
}
