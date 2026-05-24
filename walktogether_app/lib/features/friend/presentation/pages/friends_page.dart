import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/friendship_model.dart';
import '../../data/repositories/friend_repository.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final FriendRepository _friendRepo;

  List<FriendUser> _friends = [];
  List<FriendRequest> _requests = [];
  bool _friendsLoading = true;
  bool _requestsLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _friendRepo = FriendRepository(dio: context.read<DioClient>());
    _loadFriends();
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _friendsLoading = true);
    try {
      final result = await _friendRepo.getFriends(search: _searchQuery.isNotEmpty ? _searchQuery : null);
      if (!mounted) return;
      setState(() {
        _friends = result['friends'] as List<FriendUser>;
        _friendsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _friendsLoading = false);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _requestsLoading = true);
    try {
      final result = await _friendRepo.getFriendRequests();
      if (!mounted) return;
      setState(() {
        _requests = result['requests'] as List<FriendRequest>;
        _requestsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _requestsLoading = false);
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    try {
      await _friendRepo.acceptRequest(request.friendshipId);
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.friendshipId == request.friendshipId));
      _loadFriends(); // Refresh friends list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chấp nhận ${request.user.fullName}'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    try {
      await _friendRepo.rejectRequest(request.friendshipId);
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.friendshipId == request.friendshipId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Bạn bè',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textMain),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded, color: AppColors.primary),
            onPressed: () => context.push('/friends/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            const Tab(text: 'Danh sách'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lời mời'),
                  if (_requests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_requests.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsList(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm bạn bè...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) {
              _searchQuery = v;
              _loadFriends();
            },
          ),
        ),

        // Friends list
        Expanded(
          child: _friendsLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _friends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'Không tìm thấy' : 'Chưa có bạn bè',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFriends,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _friends.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return _FriendTile(
                            user: friend,
                            onTap: () => context.push('/user/${friend.id}'),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    if (_requestsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'Không có lời mời nào',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _RequestCard(
            request: request,
            onAccept: () => _acceptRequest(request),
            onReject: () => _rejectRequest(request),
            onTap: () => context.push('/user/${request.user.id}'),
          );
        },
      ),
    );
  }
}

// === Friend list tile ===

class _FriendTile extends StatelessWidget {
  final FriendUser user;
  final VoidCallback onTap;

  const _FriendTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: user.avatar != null ? CachedNetworkImageProvider(user.avatar!) : null,
          child: user.avatar == null ? const Icon(Icons.person, color: AppColors.primary) : null,
        ),
      ),
      title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: user.role == 'company_admin'
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 12, color: AppColors.secondary),
                SizedBox(width: 4),
                Text('Admin', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
              ],
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

// === Request card ===

class _RequestCard extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: request.user.avatar != null ? CachedNetworkImageProvider(request.user.avatar!) : null,
              child: request.user.avatar == null ? const Icon(Icons.person, color: AppColors.primary) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Text(request.user.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Chấp nhận', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Từ chối', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
