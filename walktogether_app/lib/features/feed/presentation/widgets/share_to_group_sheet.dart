import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../group/data/models/group_model.dart';
import '../../../group/data/repositories/group_repository.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/feed_repository.dart';

/// Bottom sheet for sharing a post to groups (with preview + multi-select).
///
/// Visibility rules:
///   - Post visibility='public' → user can share to ANY joined group
///   - Post visibility='groups' + visibleToGroups=[A,B] → only share to A or B
///
/// Also includes a "Chia sẻ lên bảng tin" option for public sharing.
class ShareToGroupSheet extends StatefulWidget {
  final PostModel post;
  final GroupRepository groupRepository;
  final FeedRepository feedRepository;
  final VoidCallback? onShared;

  const ShareToGroupSheet({
    super.key,
    required this.post,
    required this.groupRepository,
    required this.feedRepository,
    this.onShared,
  });

  @override
  State<ShareToGroupSheet> createState() => _ShareToGroupSheetState();
}

class _ShareToGroupSheetState extends State<ShareToGroupSheet> {
  List<GroupModel> _allowedGroups = [];
  final Set<String> _selectedGroupIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _shareToFeed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final allGroups = await widget.groupRepository.getGroups();
      final post = widget.post;

      // Filter groups based on original post's visibility
      List<GroupModel> allowed;
      if (post.visibility == 'public') {
        // Public posts can be shared to any group
        allowed = allGroups;
      } else {
        // Group-locked posts: only share to groups in visibleToGroups
        final allowedIds = post.visibleToGroups.map((g) => g.id).toSet();
        allowed = allGroups.where((g) => allowedIds.contains(g.id)).toList();
      }

      if (mounted) {
        setState(() {
          _allowedGroups = allowed;
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

  bool get _canShare => _selectedGroupIds.isNotEmpty || _shareToFeed;

  Future<void> _submit() async {
    if (!_canShare || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      // Share to selected groups
      if (_selectedGroupIds.isNotEmpty) {
        await widget.feedRepository.createPost(
          content: '',
          type: 'shared_post',
          sharedPostId: widget.post.id,
          visibility: 'groups',
          visibleToGroupIds: _selectedGroupIds.toList(),
        );
      }

      // Share to public feed
      if (_shareToFeed) {
        await widget.feedRepository.createPost(
          content: '',
          type: 'shared_post',
          sharedPostId: widget.post.id,
          visibility: 'public',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chia sẻ bài viết!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onShared?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chia sẻ bài viết',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable content
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                // Post preview
                _buildPostPreview(),
                const SizedBox(height: 20),

                // "Chia sẻ lên bảng tin" option
                _buildFeedOption(),
                const SizedBox(height: 16),

                // Group list header
                Row(
                  children: [
                    const Icon(Icons.groups_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Chọn nhóm để chia sẻ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_selectedGroupIds.isNotEmpty) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedGroupIds.length} nhóm',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Group list or loading
                _buildGroupList(),
              ],
            ),
          ),

          // Bottom action bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canShare && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Chia sẻ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreview() {
    final post = widget.post;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: post.author.avatar != null
                    ? CachedNetworkImageProvider(post.author.avatar!)
                    : null,
                child: post.author.avatar == null
                    ? Text(
                        post.author.fullName.isNotEmpty
                            ? post.author.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      _timeAgo(post.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.content.length > 150
                  ? '${post.content.substring(0, 150)}...'
                  : post.content,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMain),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Image thumbnail
          if (post.media.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: post.media.first.url,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 80,
                  color: Colors.grey.shade200,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedOption() {
    return InkWell(
      onTap: () => setState(() => _shareToFeed = !_shareToFeed),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _shareToFeed
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _shareToFeed ? AppColors.primary : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.public_rounded, color: AppColors.info, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chia sẻ lên bảng tin',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    'Mọi người sẽ thấy bài viết này',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: _shareToFeed,
              onChanged: (v) => setState(() => _shareToFeed = v ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 36, color: AppColors.danger),
              const SizedBox(height: 8),
              Text('Không thể tải nhóm', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_allowedGroups.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.groups_outlined, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'Không có nhóm nào để chia sẻ',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _allowedGroups.map((group) {
        final isSelected = _selectedGroupIds.contains(group.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedGroupIds.remove(group.id);
                } else {
                  _selectedGroupIds.add(group.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: group.avatar != null
                        ? CachedNetworkImageProvider(group.avatar!)
                        : null,
                    child: group.avatar == null
                        ? Text(
                            group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${group.totalMembers} thành viên',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedGroupIds.add(group.id);
                        } else {
                          _selectedGroupIds.remove(group.id);
                        }
                      });
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
