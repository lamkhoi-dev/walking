import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../contest/data/models/leaderboard_entry_model.dart';
import '../../../contest/data/repositories/contest_repository.dart';
import '../../../contest/presentation/widgets/podium_widget.dart';

import '../../data/models/post_model.dart';
import '../../data/repositories/feed_repository.dart';
import '../bloc/post_detail_bloc.dart';
import '../widgets/comment_tile.dart';
import '../widgets/like_animation_widget.dart';
import 'package:intl/intl.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  late AnimationController _likeButtonController;
  late Animation<double> _likeButtonScale;
  bool _hasText = false;

  // Leaderboard data for shared_contest posts
  List<LeaderboardEntryModel> _leaderboardEntries = [];
  bool _isLeaderboardLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _commentController.addListener(() {
      final hasText = _commentController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });

    _likeButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeButtonScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _likeButtonController,
      curve: Curves.easeInOut,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostDetailBloc>().add(const PostDetailCommentsLoadMore());
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _likeButtonController.dispose();
    super.dispose();
  }

  String? _currentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return null;
  }

  void _showMoreMenu(PostModel post) {
    final isOwner = _currentUserId() == post.author.id;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (isOwner)
                _BottomSheetItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Xóa bài viết',
                  color: AppColors.danger,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePost(post);
                  },
                ),
              _BottomSheetItem(
                icon: Icons.link_rounded,
                label: 'Sao chép liên kết',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'walktogether://post/${post.id}'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép liên kết'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              if (!isOwner)
                _BottomSheetItem(
                  icon: Icons.flag_outlined,
                  label: 'Báo cáo bài viết',
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cảm ơn bạn đã báo cáo'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePost(PostModel post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa bài viết?'),
        content: const Text('Bạn có chắc muốn xóa bài viết này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repo = context.read<FeedRepository>();
                await repo.deletePost(post.id);
                if (mounted) context.pop(true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Chia sẻ bài viết',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              _BottomSheetItem(
                icon: Icons.repeat_rounded,
                label: 'Chia sẻ lên bảng tin',
                subtitle: 'Chia sẻ bài viết này cho mọi người thấy',
                onTap: () {
                  Navigator.pop(context);
                  _shareToFeed(post);
                },
              ),
              _BottomSheetItem(
                icon: Icons.link_rounded,
                label: 'Sao chép liên kết',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'walktogether://post/${post.id}'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép liên kết'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareToFeed(PostModel post) async {
    try {
      final repo = context.read<FeedRepository>();
      await repo.createPost(
        content: '',
        type: 'shared_post',
        sharedPostId: post.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chia sẻ bài viết!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _toggleLike() {
    _likeButtonController.forward(from: 0);
    HapticFeedback.lightImpact();
    context.read<PostDetailBloc>().add(const PostDetailLikeToggled());
  }

  Future<void> _fetchLeaderboard(String contestId) async {
    if (_isLeaderboardLoading) return;
    setState(() => _isLeaderboardLoading = true);
    try {
      final repo = context.read<ContestRepository>();
      final entries = await repo.getLeaderboard(contestId);
      if (mounted) {
        setState(() {
          _leaderboardEntries = entries;
          _isLeaderboardLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLeaderboardLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: BlocBuilder<PostDetailBloc, PostDetailState>(
        builder: (context, state) {
          if (state is PostDetailLoading) {
            return _buildLoadingShimmer();
          }
          if (state is PostDetailError) {
            return _buildErrorState(state.message);
          }
          if (state is PostDetailLoaded) {
            // Fetch leaderboard for shared_contest posts
            if (state.post.type == 'shared_contest' &&
                state.post.sharedContest != null &&
                _leaderboardEntries.isEmpty &&
                !_isLeaderboardLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchLeaderboard(state.post.sharedContest!.id);
              });
            }
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      context
                          .read<PostDetailBloc>()
                          .add(PostDetailLoadRequested(widget.postId));
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Custom SliverAppBar
                        _buildSliverAppBar(state.post),

                        // Post content card
                        SliverToBoxAdapter(
                          child: _buildPostCard(state.post),
                        ),

                        // Interaction bar
                        SliverToBoxAdapter(
                          child: _buildInteractionBar(state.post),
                        ),

                        // Comments section
                        SliverToBoxAdapter(
                          child: _buildCommentsHeader(state),
                        ),

                        // Comments list
                        _buildCommentsList(state),

                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      ],
                    ),
                  ),
                ),

                // Comment input bar
                _buildCommentInput(state),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ===== SLIVER APP BAR =====
  Widget _buildSliverAppBar(PostModel post) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Row(
        children: [
          // Tiny avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: post.author.avatar != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: post.author.avatar!,
                      fit: BoxFit.cover,
                      width: 28,
                      height: 28,
                    ),
                  )
                : Center(
                    child: Text(
                      post.author.fullName.isNotEmpty
                          ? post.author.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              post.author.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade600),
          onPressed: () => _showMoreMenu(post),
        ),
      ],
    );
  }

  // ===== LOADING SHIMMER =====
  Widget _buildLoadingShimmer() {
    return SafeArea(
      child: Column(
        children: [
          // Fake app bar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name shimmer
                  Row(
                    children: [
                      _shimmerBox(46, 46, isCircle: true),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(140, 14),
                          const SizedBox(height: 6),
                          _shimmerBox(80, 12),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Content shimmer
                  _shimmerBox(double.infinity, 14),
                  const SizedBox(height: 8),
                  _shimmerBox(200, 14),
                  const SizedBox(height: 16),
                  // Image shimmer
                  _shimmerBox(double.infinity, 200, radius: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height,
      {bool isCircle = false, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }

  // ===== ERROR STATE =====
  Widget _buildErrorState(String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 32, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải bài viết',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kiểm tra kết nối mạng và thử lại',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context
                    .read<PostDetailBloc>()
                    .add(PostDetailLoadRequested(widget.postId)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== POST CARD =====
  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Avatar with online-style ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(1.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: post.author.avatar != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: post.author.avatar!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _avatarPlaceholder(post),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _formatTimeAgo(post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          Icon(
                            post.visibility == 'public'
                                ? Icons.public_rounded
                                : Icons.group_rounded,
                            size: 13,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Full content (no truncation)
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SelectableText(
                post.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textMain,
                  letterSpacing: 0.1,
                ),
              ),
            ),

          // Shared post embed — tap to view original
          if (post.type == 'shared_post' && post.sharedPost != null)
            GestureDetector(
              onTap: () => context.push('/post/${post.sharedPost!.id}'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: post.sharedPost!.author.avatar != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: post.sharedPost!.author.avatar!,
                                    fit: BoxFit.cover, width: 28, height: 28,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    post.sharedPost!.author.fullName.isNotEmpty
                                        ? post.sharedPost!.author.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.sharedPost!.author.fullName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      ],
                    ),
                    if (post.sharedPost!.content.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        post.sharedPost!.content.length > 200
                            ? '${post.sharedPost!.content.substring(0, 200)}...'
                            : post.sharedPost!.content,
                        style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMain.withValues(alpha: 0.85)),
                      ),
                    ],
                    if (post.sharedPost!.media.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: post.sharedPost!.media.first.url,
                          height: 140, width: double.infinity, fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Achievement card for shared_contest
          if (post.type == 'shared_contest' && post.sharedContest != null)
            _buildDetailedAchievementCard(post),

          // Media with double-tap like
          if (post.media.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: post.media.asMap().entries.map((entry) {
                    final media = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(top: entry.key > 0 ? 3 : 0),
                      child: LikeAnimationWidget(
                        isLiked: post.isLiked,
                        onDoubleTap: () {
                          if (!post.isLiked) _toggleLike();
                        },
                        child: CachedNetworkImage(
                          imageUrl: media.url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => Container(
                            height: 260,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary.withValues(
                                      alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 260,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  color: AppColors.textSecondary, size: 28),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ===== DETAILED ACHIEVEMENT CARD =====
  Widget _buildDetailedAchievementCard(PostModel post) {
    final contest = post.sharedContest!;
    final isActive = contest.status == 'active';
    final isCompleted = contest.status == 'completed';

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
      stepsText = _formatAchievementSteps(post.achievementSteps!);
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

    String? daysText;
    if (contest.startDate != null && contest.endDate != null) {
      final days = contest.endDate!.difference(contest.startDate!).inDays;
      daysText = '$days ngày';
    }

    return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
            // Sparkle decorations
            Positioned(
              top: 8, right: 12,
              child: Icon(Icons.auto_awesome, size: 16,
                  color: goldDark.withValues(alpha: 0.15)),
            ),
            Positioned(
              top: 26, right: 34,
              child: Icon(Icons.auto_awesome, size: 10,
                  color: goldDark.withValues(alpha: 0.1)),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Trophy + Contest name + Rank
                  Row(
                    children: [
                      // Trophy with glow
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [goldDark, goldLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: goldLight.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.emoji_events_rounded,
                            size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contest.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3E2723),
                                letterSpacing: 0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                if (contest.startDate != null &&
                                    contest.endDate != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 12,
                                          color: const Color(0xFF3E2723).withValues(alpha: 0.4)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${DateFormat('dd/MM').format(contest.startDate!)} – ${DateFormat('dd/MM').format(contest.endDate!)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color(0xFF3E2723).withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Rank badge (larger version for detail view)
                      if (rank != null && rank > 0)
                        Container(
                          width: 52, height: 52,
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
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (rank <= 3 ? goldLight : const Color(0xFF4CAF50))
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                rank <= 3
                                    ? ['🥇', '🥈', '🥉'][rank - 1]
                                    : '#$rank',
                                style: TextStyle(
                                  fontSize: rank <= 3 ? 22 : 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              if (rank > 3)
                                const Text(
                                  'hạng',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                    height: 1.3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Stats row
                  if (stepsText != null || daysText != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: goldDark.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (stepsText != null)
                            _achievementStatItem(
                              Icons.directions_walk_rounded,
                              stepsText,
                              'bước chân',
                              const Color(0xFF3E2723),
                            ),
                          if (stepsText != null && daysText != null)
                            Container(
                              width: 1, height: 28,
                              color: goldDark.withValues(alpha: 0.15),
                            ),
                          if (daysText != null)
                            _achievementStatItem(
                              Icons.schedule_rounded,
                              daysText,
                              'thời gian',
                              const Color(0xFF3E2723),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Description
                  if (contest.description != null &&
                      contest.description!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      contest.description!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFF3E2723).withValues(alpha: 0.6),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Inline leaderboard — TOP 3 ONLY
                  const SizedBox(height: 14),
                  if (_isLeaderboardLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFB8860B),
                          ),
                        ),
                      ),
                    )
                  else if (_leaderboardEntries.isNotEmpty) ...[
                    // Section header
                    Row(
                      children: [
                        Icon(Icons.leaderboard_rounded, size: 16,
                            color: goldDark.withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        Text(
                          'Bảng xếp hạng',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3E2723).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Podium (top 3 only)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        color: goldDark.withValues(alpha: 0.05),
                        child: PodiumWidget(
                          topThree: _leaderboardEntries.take(3).toList(),
                          currentUserId: _currentUserId(),
                        ),
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

  String _formatAchievementSteps(int steps) {
    if (steps >= 1000000) {
      return '${(steps / 1000000).toStringAsFixed(1)}M';
    } else if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}K';
    }
    return steps.toString();
  }

  Widget _achievementStatItem(
      IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===== INTERACTION BAR =====
  Widget _buildInteractionBar(PostModel post) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Social proof strip
          if (post.likesCount > 0 || post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Row(
                children: [
                  if (post.likesCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
                        ),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likesCount} lượt thích',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (post.commentsCount > 0)
                    Text(
                      '${post.commentsCount} bình luận',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),

          // Divider
          if (post.likesCount > 0 || post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(
                  height: 1, color: Colors.grey.shade200, thickness: 0.5),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                // Like button
                Expanded(
                  child: _InteractionButton(
                    icon: post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: 'Thích',
                    color: post.isLiked
                        ? const Color(0xFFE91E63)
                        : AppColors.textSecondary,
                    isActive: post.isLiked,
                    scaleAnimation: _likeButtonScale,
                    onTap: _toggleLike,
                  ),
                ),

                // Comment button
                Expanded(
                  child: _InteractionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Bình luận',
                    color: AppColors.textSecondary,
                    onTap: () {
                      _focusNode.requestFocus();
                    },
                  ),
                ),

                // Share button (hidden for achievement posts)
                if (post.type != 'shared_contest')
                  Expanded(
                    child: _InteractionButton(
                      icon: Icons.share_outlined,
                      label: 'Chia sẻ',
                      color: AppColors.textSecondary,
                      onTap: () => _showShareSheet(post),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== COMMENTS HEADER =====
  Widget _buildCommentsHeader(PostDetailLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'Bình luận',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${state.post.commentsCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== COMMENTS LIST =====
  Widget _buildCommentsList(PostDetailLoaded state) {
    if (state.comments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      size: 28, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có bình luận nào',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hãy là người đầu tiên bình luận! 💬',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == state.comments.length) {
            return state.isLoadingMoreComments
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }

          final comment = state.comments[index];
          final userId = _currentUserId();
          final isOwn = userId == comment.author.id;

          return CommentTile(
            comment: comment,
            isOwnComment: isOwn,
            onDelete: isOwn
                ? () => context
                    .read<PostDetailBloc>()
                    .add(PostDetailCommentDeleted(comment.id))
                : null,
          );
        },
        childCount: state.comments.length + (state.hasMoreComments ? 1 : 0),
      ),
    );
  }

  // ===== COMMENT INPUT =====
  Widget _buildCommentInput(PostDetailLoaded state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 14,
        right: 10,
        top: 10,
        bottom: 10 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: TextField(
                controller: _commentController,
                focusNode: _focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 14.5, height: 1.3),
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                    fontSize: 14.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _hasText || state.isSubmittingComment
                  ? AppColors.primaryGradient
                  : null,
              color: _hasText || state.isSubmittingComment
                  ? null
                  : Colors.grey.shade200,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: state.isSubmittingComment
                    ? null
                    : (_hasText ? _submitComment : null),
                borderRadius: BorderRadius.circular(24),
                child: Center(
                  child: state.isSubmittingComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 19,
                          color: _hasText
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    context.read<PostDetailBloc>().add(PostDetailCommentSubmitted(text));
    _commentController.clear();
    _focusNode.unfocus();
  }

  Widget _avatarPlaceholder(PostModel post) {
    final initial = post.author.fullName.isNotEmpty
        ? post.author.fullName[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
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
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}

// ===== INTERACTION BUTTON =====
class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final Animation<double>? scaleAnimation;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isActive = false,
    this.scaleAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (scaleAnimation != null) {
      return AnimatedBuilder(
        animation: scaleAnimation!,
        builder: (context, _) {
          return Transform.scale(
            scale: scaleAnimation!.value,
            child: child,
          );
        },
      );
    }

    return child;
  }
}

/// Reusable bottom sheet item for More/Share menus
class _BottomSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _BottomSheetItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textMain;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: itemColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: itemColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: itemColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
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
    );
  }
}
