import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../feed/data/models/post_model.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/data/repositories/feed_repository.dart';
import '../../data/models/friendship_model.dart';
import '../../data/repositories/friend_repository.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final FriendRepository _friendRepo;
  late final DioClient _dioClient;

  UserProfile? _profile;
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  String? _friendshipId;
  bool _isLoading = true;
  String? _error;
  bool _isOwnProfile = false;
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dioClient = context.read<DioClient>();
    _friendRepo = FriendRepository(dio: _dioClient);

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _isOwnProfile = authState.user.id == widget.userId;
    }

    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final profile = await _friendRepo.getUserProfile(widget.userId);
      if (!mounted) return;

      // Parse posts from raw data
      final posts = profile.postsRaw
          .map((p) => PostModel.fromJson(p))
          .toList();

      setState(() {
        _profile = profile;
        _friendshipStatus = profile.friendshipStatus;
        _friendshipId = profile.friendshipId;
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // === Friend actions ===

  Future<void> _sendFriendRequest() async {
    try {
      await _friendRepo.sendRequest(widget.userId);
      if (!mounted) return;
      setState(() => _friendshipStatus = FriendshipStatus.pendingSent);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lời mời kết bạn'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _acceptRequest() async {
    if (_friendshipId == null) return;
    try {
      await _friendRepo.acceptRequest(_friendshipId!);
      if (!mounted) return;
      setState(() => _friendshipStatus = FriendshipStatus.friends);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận lời mời'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _rejectRequest() async {
    if (_friendshipId == null) return;
    try {
      await _friendRepo.rejectRequest(_friendshipId!);
      if (!mounted) return;
      setState(() { _friendshipStatus = FriendshipStatus.none; _friendshipId = null; });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _cancelRequest() async {
    if (_friendshipId == null) return;
    try {
      await _friendRepo.cancelRequest(_friendshipId!);
      if (!mounted) return;
      setState(() { _friendshipStatus = FriendshipStatus.none; _friendshipId = null; });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _unfriend() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ kết bạn?'),
        content: Text('Bạn có chắc muốn huỷ kết bạn với ${_profile?.user.fullName ?? ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ kết bạn', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _friendRepo.unfriend(widget.userId);
      if (!mounted) return;
      setState(() { _friendshipStatus = FriendshipStatus.none; _friendshipId = null; });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_error ?? 'Không tìm thấy người dùng', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadProfile, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final user = _profile!.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          // === MESH GRADIENT HEADER ===
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.navy,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!_isOwnProfile)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {},
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'block', child: Text('Chặn người dùng')),
                    const PopupMenuItem(value: 'report', child: Text('Báo cáo')),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.profileGradient),
                child: Stack(
                  children: [
                    // Mesh glow overlays
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.3, -0.5),
                            radius: 1.2,
                            colors: [AppColors.primary.withValues(alpha: 0.15), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.6, 0.3),
                            radius: 0.9,
                            colors: [AppColors.indigo.withValues(alpha: 0.2), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Content — centered avatar + name
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            // Avatar with border
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                                ],
                              ),
                              child: AvatarWidget(
                                imageUrl: user.avatar,
                                name: user.fullName,
                                size: 96,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Name
                            Text(
                              user.fullName,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 6),
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    user.role == 'company_admin' ? Icons.verified_rounded : Icons.person,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    user.role == 'company_admin' ? 'Quản trị viên' : 'Thành viên',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // Company name
                            if (_profile!.company != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _profile!.company!.name,
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === FLOATING STATS + ACTION BUTTONS + TABS ===
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Floating social stats card
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.indigo.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _SocialStat(count: _profile!.friendCount.toString(), label: 'Bạn bè'),
                            VerticalDivider(color: AppColors.divider.withValues(alpha: 0.5), width: 1, indent: 4, endIndent: 4),
                            _SocialStat(count: _profile!.postCount.toString(), label: 'Bài viết'),
                            VerticalDivider(color: AppColors.divider.withValues(alpha: 0.5), width: 1, indent: 4, endIndent: 4),
                            _SocialStat(count: _profile!.groupCount.toString(), label: 'Nhóm'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Action buttons (only for other users)
                if (!_isOwnProfile) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildFriendActionButton(),
                  ),
                ],

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Bài viết'),
                      Tab(text: 'Thông tin'),
                      Tab(text: 'Thống kê'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildInfoTab(),
            _buildStatsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendActionButton() {
    switch (_friendshipStatus) {
      case FriendshipStatus.none:
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _sendFriendRequest,
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text('Kết bạn', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        );

      case FriendshipStatus.pendingSent:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.hourglass_top_rounded, size: 20),
                label: const Text('Đã gửi lời mời', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _cancelRequest,
              child: const Text('Huỷ lời mời', style: TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          ],
        );

      case FriendshipStatus.pendingReceived:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _acceptRequest,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Chấp nhận', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _rejectRequest,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        );

      case FriendshipStatus.friends:
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _unfriend,
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('Bạn bè ✓', style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

      case FriendshipStatus.self:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.article_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('Chưa có bài viết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain)),
              const SizedBox(height: 8),
              Text(
                '${_profile!.user.fullName} chưa đăng bài viết nào',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return PostCard(
            post: post,
            isCompanyAdmin: false,
            onLike: () async {
              try {
                final repo = FeedRepository(_dioClient);
                await repo.toggleLike(post.id);
                _loadProfile();
              } catch (_) {}
            },
            onComment: () async {
              await context.push('/post/${post.id}');
              _loadProfile();
            },
            onTap: () async {
              await context.push('/post/${post.id}');
              _loadProfile();
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoTab() {
    final user = _profile!.user;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoTile(icon: Icons.person_rounded, label: 'Tên', value: user.fullName),
        if (user.role != null)
          _InfoTile(icon: Icons.badge_rounded, label: 'Vai trò', value: user.role == 'company_admin' ? 'Quản trị viên' : 'Thành viên'),
        if (_profile!.company != null)
          _InfoTile(icon: Icons.business_rounded, label: 'Công ty', value: _profile!.company!.name),
        _InfoTile(icon: Icons.people_rounded, label: 'Bạn bè', value: '${_profile!.friendCount} bạn bè'),
        _InfoTile(icon: Icons.article_rounded, label: 'Bài viết', value: '${_profile!.postCount} bài viết'),
        _InfoTile(icon: Icons.group_rounded, label: 'Nhóm', value: '${_profile!.groupCount} nhóm'),
      ],
    );
  }

  Widget _buildStatsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.indigo.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.indigo),
            ),
            const SizedBox(height: 20),
            const Text('Thống kê', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain)),
            const SizedBox(height: 8),
            Text(
              _friendshipStatus == FriendshipStatus.friends
                  ? 'Thống kê hoạt động sẽ hiển thị ở đây'
                  : 'Kết bạn để xem thống kê hoạt động',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// === Supporting Widgets ===

class _SocialStat extends StatelessWidget {
  final String count;
  final String label;

  const _SocialStat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textMain)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
