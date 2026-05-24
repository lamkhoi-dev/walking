import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/friendship_model.dart';
import '../../data/repositories/friend_repository.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  late final FriendRepository _friendRepo;
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<FriendUser> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _friendRepo = FriendRepository(dio: context.read<DioClient>());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _search(query.trim());
      } else {
        setState(() { _results = []; _hasSearched = false; });
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() { _isLoading = true; _hasSearched = true; });
    try {
      final result = await _friendRepo.searchUsers(query: query);
      if (!mounted) return;
      setState(() {
        _results = result['users'] as List<FriendUser>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest(FriendUser user, int index) async {
    try {
      await _friendRepo.sendRequest(user.id);
      if (!mounted) return;
      // Update local state
      setState(() {
        _results[index] = FriendUser(
          id: user.id,
          fullName: user.fullName,
          avatar: user.avatar,
          role: user.role,
          companyId: user.companyId,
          friendshipStatus: FriendshipStatus.pendingSent,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi lời mời đến ${user.fullName}'), backgroundColor: AppColors.success),
      );
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
          'Tìm kiếm',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textMain),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nhập tên để tìm kiếm...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() { _results = []; _hasSearched = false; });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'Tìm người dùng để kết bạn',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Không tìm thấy người dùng',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return _SearchResultTile(
                                user: user,
                                onTap: () => context.push('/user/${user.id}'),
                                onAddFriend: user.friendshipStatus == FriendshipStatus.none
                                    ? () => _sendRequest(user, index)
                                    : null,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final FriendUser user;
  final VoidCallback onTap;
  final VoidCallback? onAddFriend;

  const _SearchResultTile({
    required this.user,
    required this.onTap,
    this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: user.avatar != null ? CachedNetworkImageProvider(user.avatar!) : null,
          child: user.avatar == null ? const Icon(Icons.person, color: AppColors.primary) : null,
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
        trailing: _buildStatusButton(),
      ),
    );
  }

  Widget _buildStatusButton() {
    switch (user.friendshipStatus) {
      case FriendshipStatus.none:
        return SizedBox(
          height: 34,
          child: ElevatedButton.icon(
            onPressed: onAddFriend,
            icon: const Icon(Icons.person_add_rounded, size: 16),
            label: const Text('Kết bạn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        );
      case FriendshipStatus.pendingSent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Đã gửi', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        );
      case FriendshipStatus.pendingReceived:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Phản hồi', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        );
      case FriendshipStatus.friends:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: AppColors.secondary),
            SizedBox(width: 4),
            Text('Bạn bè', style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
          ],
        );
      case FriendshipStatus.self:
        return const SizedBox.shrink();
    }
  }
}
