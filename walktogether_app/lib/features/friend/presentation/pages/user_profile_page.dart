import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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

  UserProfile? _profile;
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  String? _friendshipId;
  bool _isLoading = true;
  String? _error;
  bool _isOwnProfile = false;
  bool _postsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _friendRepo = FriendRepository(dio: context.read<DioClient>());

    // Check if this is own profile
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
      setState(() {
        _profile = profile;
        _friendshipStatus = profile.friendshipStatus;
        _friendshipId = profile.friendshipId;
        _isLoading = false;
        _postsLoading = false;
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
      setState(() {
        _friendshipStatus = FriendshipStatus.pendingSent;
      });
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
          // === HEADER with gradient ===
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!_isOwnProfile)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'block') {
                      // TODO: block user
                    } else if (v == 'report') {
                      // TODO: report user
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'block', child: Text('Chặn người dùng')),
                    const PopupMenuItem(value: 'report', child: Text('Báo cáo')),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      // Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: user.avatar != null
                              ? CachedNetworkImage(
                                  imageUrl: user.avatar!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: AppColors.primaryLight,
                                    child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.primaryLight,
                                    child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                                  ),
                                )
                              : Container(
                                  color: AppColors.primaryLight,
                                  child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Role badge
                      if (user.role != null && user.role == 'company_admin')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_rounded, size: 14, color: Colors.white70),
                              SizedBox(width: 4),
                              Text('Company Admin', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      // Company name
                      if (_profile!.company != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _profile!.company!.name,
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // === STATS + ACTIONS ===
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        _StatItem(
                          count: _profile!.friendCount,
                          label: 'Bạn bè',
                          onTap: () => context.push('/friends'),
                        ),
                        _divider(),
                        _StatItem(
                          count: 0, // TODO: post count from pagination
                          label: 'Bài viết',
                        ),
                      ],
                    ),
                  ),

                  // Action buttons (only for other users)
                  if (!_isOwnProfile) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Posts tab
            _buildPostsTab(),
            // Info tab
            _buildInfoTab(),
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
    // For now show a simple message; posts will be loaded from profile endpoint
    return Center(
      child: _postsLoading
          ? const CircularProgressIndicator(color: AppColors.primary)
          : const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Bài viết sẽ hiển thị ở đây',
                style: TextStyle(color: AppColors.textSecondary),
              ),
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
        _InfoTile(
          icon: Icons.people_rounded,
          label: 'Bạn bè',
          value: '${_profile!.friendCount} bạn bè',
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.divider,
      );
}

// === Supporting Widgets ===

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (onTap != null) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                ],
              ],
            ),
          ],
        ),
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
