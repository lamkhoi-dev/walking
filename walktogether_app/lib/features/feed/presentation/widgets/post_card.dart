import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/post_model.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onShare,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (post.content.isNotEmpty) _buildContent(),
            if (post.media.isNotEmpty) _buildMediaGrid(context),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: post.author.avatar != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: post.author.avatar!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _avatarPlaceholder(),
                      errorWidget: (_, __, ___) => _avatarPlaceholder(),
                    ),
                  )
                : _avatarPlaceholder(),
          ),
          const SizedBox(width: 10),

          // Author + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(post.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('·', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5))),
                    const SizedBox(width: 4),
                    Icon(
                      post.visibility == 'public' ? Icons.public_rounded : Icons.group_rounded,
                      size: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu
          if (onDelete != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary, size: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete', child: Text('Xóa bài viết')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    final initials = post.author.fullName.isNotEmpty ? post.author.fullName[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(
        post.content,
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: AppColors.textMain,
        ),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context) {
    final images = post.media;
    final count = images.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: count == 1
            ? _singleImage(images[0])
            : count == 2
                ? _twoImages(images)
                : count == 3
                    ? _threeImages(images)
                    : _fourImages(images),
      ),
    );
  }

  Widget _singleImage(PostMedia media) {
    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 240,
      placeholder: (_, __) => _imagePlaceholder(240),
      errorWidget: (_, __, ___) => _imagePlaceholder(240),
    );
  }

  Widget _twoImages(List<PostMedia> images) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: images[0].url,
              fit: BoxFit.cover,
              height: 200,
              placeholder: (_, __) => _imagePlaceholder(200),
              errorWidget: (_, __, ___) => _imagePlaceholder(200),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: CachedNetworkImage(
              imageUrl: images[1].url,
              fit: BoxFit.cover,
              height: 200,
              placeholder: (_, __) => _imagePlaceholder(200),
              errorWidget: (_, __, ___) => _imagePlaceholder(200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _threeImages(List<PostMedia> images) {
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CachedNetworkImage(
              imageUrl: images[0].url,
              fit: BoxFit.cover,
              height: 220,
              placeholder: (_, __) => _imagePlaceholder(220),
              errorWidget: (_, __, ___) => _imagePlaceholder(220),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: images[1].url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => _imagePlaceholder(110),
                    errorWidget: (_, __, ___) => _imagePlaceholder(110),
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: images[2].url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => _imagePlaceholder(110),
                    errorWidget: (_, __, ___) => _imagePlaceholder(110),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fourImages(List<PostMedia> images) {
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: images[0].url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imagePlaceholder(110),
                    errorWidget: (_, __, ___) => _imagePlaceholder(110),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: images[1].url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imagePlaceholder(110),
                    errorWidget: (_, __, ___) => _imagePlaceholder(110),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: images[2].url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imagePlaceholder(110),
                    errorWidget: (_, __, ___) => _imagePlaceholder(110),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: images[3].url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _imagePlaceholder(110),
                        errorWidget: (_, __, ___) => _imagePlaceholder(110),
                      ),
                      if (post.media.length > 4)
                        Container(
                          color: Colors.black38,
                          child: Center(
                            child: Text(
                              '+${post.media.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(double height) {
    return Container(
      height: height,
      color: AppColors.divider.withValues(alpha: 0.4),
      child: const Center(
        child: Icon(Icons.image_rounded, color: AppColors.textSecondary, size: 28),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: [
          // Like button
          _ActionButton(
            icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: post.likesCount > 0 ? '${post.likesCount}' : 'Thích',
            color: post.isLiked ? const Color(0xFFE91E63) : AppColors.textSecondary,
            onTap: onLike,
          ),
          const SizedBox(width: 4),

          // Comment button
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: post.commentsCount > 0 ? '${post.commentsCount}' : 'Bình luận',
            color: AppColors.textSecondary,
            onTap: onComment,
          ),
          const SizedBox(width: 4),

          // Share button
          if (onShare != null)
            _ActionButton(
              icon: Icons.share_rounded,
              label: 'Chia sẻ',
              color: AppColors.textSecondary,
              onTap: onShare!,
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
