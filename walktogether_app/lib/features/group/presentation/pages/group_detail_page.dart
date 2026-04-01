import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/presentation/bloc/conversation_list_bloc.dart';
import '../../../feed/data/models/post_model.dart';
import '../../../feed/data/repositories/feed_repository.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../data/repositories/group_repository.dart';
import '../bloc/group_detail_bloc.dart';
import '../widgets/member_list_tile.dart';
import '../widgets/member_selector.dart';

/// Group detail page with tabs: Members, Info
class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<GroupDetailBloc>().add(GroupDetailLoadRequested(widget.groupId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Check if current user can manage this group (admin of the group's company)
  bool _canManageGroup(BuildContext context, String groupCompanyId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      // Must be company_admin AND from the same company as the group
      return user.role == 'company_admin' && user.companyId == groupCompanyId;
    }
    return false;
  }

  String? _currentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConversationListBloc, ConversationListState>(
          listener: (context, convState) {
            if (convState is ConversationListDirectCreated) {
              context.push('/chat/${convState.conversation.id}');
            } else if (convState is ConversationListError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(convState.message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
        ),
      ],
      child: BlocConsumer<GroupDetailBloc, GroupDetailState>(
      listener: (context, state) {
        if (state is GroupDetailActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
        if (state is GroupDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is GroupDetailLoading) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            body: const LoadingWidget(message: 'Đang tải...'),
          );
        }

        if (state is GroupDetailError && state is! GroupDetailActionSuccess) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            body: AppErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<GroupDetailBloc>().add(
                      GroupDetailLoadRequested(widget.groupId),
                    );
              },
            ),
          );
        }

        // Get group from loaded or action success state
        final group = state is GroupDetailLoaded
            ? state.group
            : state is GroupDetailActionSuccess
                ? state.group
                : null;

        if (group == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            body: const LoadingWidget(),
          );
        }

        // Check if user can manage this group (must be admin of group's company)
        final canManage = _canManageGroup(context, group.companyId);
        final currentUserId = _currentUserId(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.white),
                      onPressed: () => context.push('/groups/${group.id}/qr'),
                      tooltip: 'Mã QR nhóm',
                    ),
                    if (canManage)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(context, group.name, group.description);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Chỉnh sửa'),
                              ],
                            ),
                          ),
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
                            AvatarWidget(
                              imageUrl: group.avatar,
                              name: group.name,
                              size: 68,
                              borderColor: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              group.name,
                              style: AppTextStyles.heading3.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${group.totalMembers} thành viên',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Bài viết'),
                      Tab(text: 'Thành viên'),
                      Tab(text: 'Thông tin'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Group Feed (Posts)
                _GroupFeedTab(groupId: widget.groupId),

                // Tab 2: Members
                _buildMembersTab(context, canManage, currentUserId, group),

                // Tab 3: Info
                _buildInfoTab(context, group),
              ],
            ),
          ),
        );
      },
    ),
    );
  }

  Widget _buildMembersTab(
    BuildContext context,
    bool canManage,
    String? currentUserId,
    dynamic group,
  ) {
    return Column(
      children: [
        // Add members button for admin of same company
        if (canManage)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddMembersSheet(context, group),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Thêm thành viên'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),

        // Members list
        Expanded(
          child: group.members.isEmpty
              ? Center(
                  child: Text(
                    'Chưa có thành viên',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: group.members.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    color: AppColors.divider.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final member = group.members[index];
                    final isCreator = member.id == group.createdById;

                    return MemberListTile(
                      member: member,
                      isCreator: isCreator,
                      showRemoveButton: canManage && member.id != currentUserId,
                      onRemove: () => _confirmRemoveMember(
                        context,
                        group.id,
                        member.id,
                        member.fullName,
                      ),
                      onTap: member.id != currentUserId
                          ? () {
                              // Create or open a direct conversation with this member
                              context
                                  .read<ConversationListBloc>()
                                  .add(ConversationListCreateDirect(member.id));
                            }
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(BuildContext context, dynamic group) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description section
        _InfoCard(
          title: 'Mô tả',
          icon: Icons.description_outlined,
          child: Text(
            group.description?.isNotEmpty == true
                ? group.description!
                : 'Chưa có mô tả',
            style: AppTextStyles.bodyMedium.copyWith(
              color: group.description?.isNotEmpty == true
                  ? AppColors.textMain
                  : AppColors.textSecondary,
              fontStyle: group.description?.isNotEmpty == true
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Creator
        if (group.createdByName != null)
          _InfoCard(
            title: 'Người tạo',
            icon: Icons.person_outline,
            child: Text(
              group.createdByName!,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        const SizedBox(height: 12),

        // Created date
        _InfoCard(
          title: 'Ngày tạo',
          icon: Icons.calendar_today_outlined,
          child: Text(
            _formatDate(group.createdAt),
            style: AppTextStyles.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),

        // Stats
        _InfoCard(
          title: 'Thống kê',
          icon: Icons.bar_chart_outlined,
          child: Row(
            children: [
              _StatItem(
                label: 'Thành viên',
                value: '${group.totalMembers}',
                icon: Icons.people_outline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Contest button
        InkWell(
          onTap: () => context.push(
            '/contests/group/${group.id}?name=${Uri.encodeComponent(group.name)}&companyId=${group.companyId}',
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2DA831)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuộc thi đi bộ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Xem và tham gia cuộc thi của nhóm',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, String currentName, String? currentDesc) {
    final nameController = TextEditingController(text: currentName);
    final descController = TextEditingController(text: currentDesc ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chỉnh sửa nhóm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên nhóm',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final data = <String, dynamic>{};
              if (nameController.text.trim().isNotEmpty) {
                data['name'] = nameController.text.trim();
              }
              data['description'] = descController.text.trim();
              if (data.isNotEmpty) {
                context.read<GroupDetailBloc>().add(
                      GroupDetailUpdate(widget.groupId, data),
                    );
              }
            },
            child: const Text(
              'Lưu',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMembersSheet(BuildContext context, dynamic group) {
    final existingIds = group.members.map<String>((m) => m.id as String).toList();
    List<String> selectedIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Member selector
                  Expanded(
                    child: MemberSelector(
                      repository: context.read<GroupRepository>(),
                      selectedMemberIds: const [],
                      excludeMemberIds: existingIds,
                      onChanged: (ids) => selectedIds = ids,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        if (selectedIds.isNotEmpty) {
                          context.read<GroupDetailBloc>().add(
                                GroupDetailAddMembers(widget.groupId, selectedIds),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Thêm thành viên'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRemoveMember(
    BuildContext context,
    String groupId,
    String userId,
    String userName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thành viên'),
        content: Text('Bạn có chắc muốn xóa "$userName" khỏi nhóm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GroupDetailBloc>().add(
                    GroupDetailRemoveMember(groupId, userId),
                  );
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// === Info card widget ===
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// === Stat item widget ===
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.heading4),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// Group feed tab — shows posts shared to this group
class _GroupFeedTab extends StatefulWidget {
  final String groupId;
  const _GroupFeedTab({required this.groupId});

  @override
  State<_GroupFeedTab> createState() => _GroupFeedTabState();
}

class _GroupFeedTabState extends State<_GroupFeedTab> with AutomaticKeepAliveClientMixin {
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isEmpty = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = context.read<FeedRepository>();
      final response = await repo.getFeed(filter: 'group:${widget.groupId}');
      if (mounted) {
        setState(() {
          _posts = response.posts;
          _isEmpty = _posts.isEmpty;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEmpty = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Ch\u01b0a c\u00f3 b\u00e0i vi\u1ebft n\u00e0o',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Chia s\u1ebb b\u00e0i vi\u1ebft t\u1eeb b\u1ea3ng tin v\u00e0o nh\u00f3m n\u00e0y',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return PostCard(
            post: post,
            onLike: () {},
            onComment: () => context.push('/posts/${post.id}'),
            onTap: () => context.push('/posts/${post.id}'),
          );
        },
      ),
    );
  }
}
