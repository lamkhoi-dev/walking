import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/conversation_list_bloc.dart';
import '../widgets/conversation_tile.dart';

/// Chat list screen showing all conversations
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ConversationListBloc>().add(ConversationListLoadRequested());
  }

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Search conversations
            },
          ),
        ],
      ),
      body: BlocConsumer<ConversationListBloc, ConversationListState>(
        listener: (context, state) {
          if (state is ConversationListDirectCreated) {
            // Navigate to the created DM
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
            return _buildError(state.message);
          }

          final conversations = state is ConversationListLoaded
              ? state.conversations
              : state is ConversationListDirectCreated
                  ? state.conversations
                  : <dynamic>[];

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
                  currentUserId: _currentUserId,
                  onTap: () async {
                    await context.push(
                      '/chat/${conversation.id}?title=${Uri.encodeComponent(conversation.displayName(_currentUserId))}&groupId=${conversation.groupId ?? ''}',
                    );
                    if (context.mounted) {
                      context.read<ConversationListBloc>().add(
                        ConversationListMarkRead(conversation.id),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
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
            'Chưa có cuộc trò chuyện',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tin nhắn nhóm sẽ tự động xuất hiện\nkhi bạn tham gia nhóm',
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

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.danger.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Không thể tải tin nhắn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context
                  .read<ConversationListBloc>()
                  .add(ConversationListLoadRequested());
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 44),
            ),
          ),
        ],
      ),
    );
  }
}
