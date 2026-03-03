import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/conversation_model.dart';
import 'package:intl/intl.dart';

/// Single conversation row in the conversation list
class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = conversation.displayName(currentUserId);
    final avatarUrl = conversation.displayAvatar(currentUserId);
    final lastMsg = conversation.lastMessage;
    final unread = conversation.unreadCount;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: unread > 0
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(name, avatarUrl),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                unread > 0 ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMsg != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(lastMsg.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: unread > 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message + unread badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _lastMessagePreview(lastMsg),
                          style: TextStyle(
                            fontSize: 13,
                            color: unread > 0
                                ? AppColors.textMain
                                : AppColors.textSecondary,
                            fontWeight: unread > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? avatarUrl) {
    final isGroup = conversation.type == 'group';

    return CircleAvatar(
      radius: 26,
      backgroundColor: isGroup
          ? AppColors.secondary.withValues(alpha: 0.15)
          : AppColors.primary.withValues(alpha: 0.15),
      backgroundImage:
          avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? isGroup
              ? Icon(Icons.group, color: AppColors.secondary, size: 24)
              : Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                )
          : null,
    );
  }

  String _lastMessagePreview(MessageModel? msg) {
    if (msg == null) return 'Chưa có tin nhắn';
    if (msg.isSystem) return msg.content;
    if (msg.isImage) return '📷 Hình ảnh';

    final prefix = msg.isMine(currentUserId)
        ? 'Bạn: '
        : '${msg.senderName ?? ''}: ';
    return '$prefix${msg.content}';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE', 'vi').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}
