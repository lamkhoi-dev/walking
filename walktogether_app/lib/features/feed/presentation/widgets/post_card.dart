import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/post_model.dart';
import 'image_gallery_viewer.dart';
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
            // Shared post embed — tap to view original
            if (post.type == 'shared_post' && post.sharedPost != null)
              GestureDetector(
                onTap: () => context.push('/post/${post.sharedPost!.id}'),
                child: _buildSharedPostEmbed(),
              ),
            // Shared contest embed
            if (post.type == 'shared_contest' && post.sharedContest != null)
              _buildSharedContestEmbed(),
            if (post.media.isNotEmpty) _buildMediaGrid(context),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedPostEmbed() {
    final shared = post.sharedPost!;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared post author
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: shared.author.avatar != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: shared.author.avatar!,
                          fit: BoxFit.cover,
                          width: 28,
                          height: 28,
                        ),
                      )
                    : Center(
                        child: Text(
                          shared.author.fullName.isNotEmpty
                              ? shared.author.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shared.author.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (shared.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              shared.content.length > 120
                  ? '${shared.content.substring(0, 120)}...'
                  : shared.content,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textMain.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (shared.media.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: shared.media.first.url,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => _imagePlaceholder(140),
                errorWidget: (_, __, ___) => _imagePlaceholder(140),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSharedContestEmbed() {
    final contest = post.sharedContest!;
    final isActive = contest.status == 'active';
    final isCompleted = contest.status == 'completed';

    // Gold/green color palette
    const goldDark = Color(0xFFB8860B);
    const goldLight = Color(0xFFFFD700);
    final statusColor = isActive
        ? const Color(0xFF4CAF50)
        : isCompleted
            ? const Color(0xFF2196F3)
            : Colors.grey;
    final statusLabel = isActive
        ? 'Đang diễn ra'
        : isCompleted
            ? 'Đã kết thúc'
            : contest.status;

    // Use dedicated fields (with regex fallback for old posts)
    int? rank = post.achievementRank;
    String? stepsText;
    if (post.achievementSteps != null && post.achievementSteps! > 0) {
      stepsText = _formatSteps(post.achievementSteps!);
    }
    // Fallback: parse from content for old posts
    if (rank == null) {
      final rankMatch = RegExp(r'Hạng #(\d+)').firstMatch(post.content);
      if (rankMatch != null) rank = int.tryParse(rankMatch.group(1)!);
    }
    if (stepsText == null) {
      final stepsMatch = RegExp(r'với (.+?) bước').firstMatch(post.content);
      if (stepsMatch != null) stepsText = stepsMatch.group(1);
    }

    // Days info
    String? daysText;
    if (contest.startDate != null && contest.endDate != null) {
      final days = contest.endDate!.difference(contest.startDate!).inDays;
      daysText = '$days ngày';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0), Color(0xFFFFFDE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: goldDark.withValues(alpha: 0.25), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: goldDark.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle sparkle decoration
          Positioned(
            top: 8, right: 12,
            child: Icon(Icons.auto_awesome, size: 14,
                color: goldDark.withValues(alpha: 0.15)),
          ),
          Positioned(
            top: 22, right: 30,
            child: Icon(Icons.auto_awesome, size: 10,
                color: goldDark.withValues(alpha: 0.1)),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Trophy + Contest name + Status
                Row(
                  children: [
                    // Trophy with glow
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [goldDark, goldLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: goldLight.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          size: 26, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contest.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3E2723),
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              if (contest.startDate != null &&
                                  contest.endDate != null) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.calendar_today_rounded,
                                    size: 11,
                                    color: const Color(0xFF3E2723).withValues(alpha: 0.4)),
                                const SizedBox(width: 3),
                                Text(
                                  '${DateFormat('dd/MM').format(contest.startDate!)} – ${DateFormat('dd/MM').format(contest.endDate!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF3E2723).withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Rank badge (if available)
                    if (rank != null && rank > 0)
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: rank == 1
                                ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
                                : rank == 2
                                    ? [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)]
                                    : rank == 3
                                        ? [const Color(0xFFCD7F32), const Color(0xFFA0522D)]
                                        : [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (rank <= 3 ? goldLight : const Color(0xFF4CAF50))
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '#$rank',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const Text(
                              'hạng',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Stats row
                if (stepsText != null || daysText != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: goldDark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (stepsText != null)
                          _contestStatItem(Icons.directions_walk_rounded,
                              stepsText, 'bước', const Color(0xFF3E2723)),
                        if (stepsText != null && daysText != null)
                          Container(
                              width: 1, height: 24,
                              color: goldDark.withValues(alpha: 0.15)),
                        if (daysText != null)
                          _contestStatItem(Icons.schedule_rounded,
                              daysText, 'thời gian', const Color(0xFF3E2723)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000000) {
      return '${(steps / 1000000).toStringAsFixed(1)}M';
    } else if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}K';
    }
    return steps.toString();
  }

  Widget _contestStatItem(
      IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
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
    final heroPrefix = 'post_${post.id}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: count == 1
            ? _singleImage(context, images[0], heroPrefix)
            : count == 2
                ? _twoImages(context, images, heroPrefix)
                : count == 3
                    ? _threeImages(context, images, heroPrefix)
                    : _fourImages(context, images, heroPrefix),
      ),
    );
  }

  /// Tappable image with Hero animation → opens gallery at given index
  Widget _tappableImage(
    BuildContext context,
    PostMedia media,
    int index,
    String heroPrefix, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    final allUrls = post.media.map((m) => m.url).toList();

    return GestureDetector(
      onTap: () => ImageGalleryViewer.show(
        context,
        imageUrls: allUrls,
        initialIndex: index,
        heroTagPrefix: heroPrefix,
      ),
      child: Hero(
        tag: '${heroPrefix}_$index',
        child: CachedNetworkImage(
          imageUrl: media.url,
          fit: fit,
          height: height,
          width: width ?? double.infinity,
          placeholder: (_, __) => _imagePlaceholder(height ?? 200),
          errorWidget: (_, __, ___) => _imagePlaceholder(height ?? 200),
        ),
      ),
    );
  }

  Widget _singleImage(BuildContext ctx, PostMedia media, String heroPrefix) {
    return _tappableImage(ctx, media, 0, heroPrefix, height: 240);
  }

  Widget _twoImages(BuildContext ctx, List<PostMedia> images, String heroPrefix) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: _tappableImage(ctx, images[0], 0, heroPrefix, height: 200),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _tappableImage(ctx, images[1], 1, heroPrefix, height: 200),
          ),
        ],
      ),
    );
  }

  Widget _threeImages(BuildContext ctx, List<PostMedia> images, String heroPrefix) {
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _tappableImage(ctx, images[0], 0, heroPrefix, height: 220),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _tappableImage(ctx, images[1], 1, heroPrefix),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: _tappableImage(ctx, images[2], 2, heroPrefix),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fourImages(BuildContext ctx, List<PostMedia> images, String heroPrefix) {
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _tappableImage(ctx, images[0], 0, heroPrefix),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: _tappableImage(ctx, images[1], 1, heroPrefix),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _tappableImage(ctx, images[2], 2, heroPrefix),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _tappableImage(ctx, images[3], 3, heroPrefix),
                      if (post.media.length > 4)
                        GestureDetector(
                          onTap: () => ImageGalleryViewer.show(
                            ctx,
                            imageUrls: post.media.map((m) => m.url).toList(),
                            initialIndex: 3,
                            heroTagPrefix: heroPrefix,
                          ),
                          child: Container(
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
