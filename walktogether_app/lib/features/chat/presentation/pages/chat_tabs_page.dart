import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../group/presentation/bloc/group_list_bloc.dart';
import '../../../group/presentation/widgets/group_card.dart';
import '../bloc/conversation_list_bloc.dart';
import '../widgets/conversation_tile.dart';

/// Chat page with 2 tabs: "Tin nhắn" (DMs) and "Nhóm" (Groups)
class ChatTabsPage extends StatefulWidget {
  const ChatTabsPage({super.key});

  @override
  State<ChatTabsPage> createState() => _ChatTabsPageState();
}

class _ChatTabsPageState extends State<ChatTabsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ConversationListBloc>().add(ConversationListLoadRequested());
    context.read<GroupListBloc>().add(GroupListLoadRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  bool _isCompanyAdmin(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.role == 'company_admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Chat', style: AppTextStyles.heading3),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.textMain),
            onPressed: () => context.push('/groups/qr-scanner'),
            tooltip: 'Quét QR',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Tin nhắn'),
            Tab(text: 'Nhóm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DirectMessagesTab(currentUserId: _currentUserId),
          _GroupsTab(isAdmin: _isCompanyAdmin(context)),
        ],
      ),
    );
  }
}

/// Tab 1: Direct messages
class _DirectMessagesTab extends StatelessWidget {
  final String currentUserId;
  const _DirectMessagesTab({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationListBloc, ConversationListState>(
      listener: (context, state) {
        if (state is ConversationListDirectCreated) {
          context.push('/chat/${state.conversation.id}');
        }
      },
      builder: (context, state) {
        if (state is ConversationListLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is ConversationListError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () {
              context
                  .read<ConversationListBloc>()
                  .add(ConversationListLoadRequested());
            },
          );
        }

        final allConversations = state is ConversationListLoaded
            ? state.conversations
            : state is ConversationListDirectCreated
                ? state.conversations
                : <dynamic>[];

        // Filter to show only direct conversations
        final conversations = allConversations
            .where((c) => c.type == 'direct')
            .toList();

        if (conversations.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            context
                .read<ConversationListBloc>()
                .add(ConversationListRefreshRequested());
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 72,
              color: AppColors.divider.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ConversationTile(
                conversation: conversation,
                currentUserId: currentUserId,
                onTap: () => context.push('/chat/${conversation.id}'),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tin nhắn riêng sẽ xuất hiện ở đây',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 2: Groups
class _GroupsTab extends StatelessWidget {
  final bool isAdmin;
  const _GroupsTab({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<GroupListBloc, GroupListState>(
          builder: (context, state) {
            if (state is GroupListLoading) {
              return const LoadingWidget(message: 'Đang tải nhóm...');
            }

            if (state is GroupListError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<GroupListBloc>().add(GroupListLoadRequested());
                },
              );
            }

            if (state is GroupListLoaded) {
              if (state.groups.isEmpty) {
                return _buildEmpty();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<GroupListBloc>().add(GroupListRefreshRequested());
                },
                color: AppColors.primary,
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: isAdmin ? 80 : 8,
                  ),
                  itemCount: state.groups.length,
                  itemBuilder: (context, index) {
                    final group = state.groups[index];
                    return GroupCard(
                      group: group,
                      onTap: () {
                        // Tap → go to group chat
                        if (group.conversationId != null) {
                          context.push(
                            '/chat/${group.conversationId}?title=${Uri.encodeComponent(group.name)}',
                          );
                        } else {
                          context.push('/groups/${group.id}');
                        }
                      },
                      onLongPress: () =>
                          context.push('/groups/${group.id}'),
                    );
                  },
                ),
              );
            }

            return const LoadingWidget();
          },
        ),
        if (isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/groups/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tạo nhóm'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có nhóm nào',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quét mã QR để tham gia nhóm!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
