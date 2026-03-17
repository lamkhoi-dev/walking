import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_bubble.dart';
import '../widgets/system_message.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';

/// Full chat screen with messages, input, and typing indicator
class ChatPage extends StatefulWidget {
  final String conversationId;
  final String? title;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.title,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _isInitialLoad = true;

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  String get _currentUserName {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.fullName;
    return '';
  }

  String? get _currentUserAvatar {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.avatar;
    return null;
  }

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatLoadRequested(widget.conversationId));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 50 &&
        !_isLoadingMore) {
      _isLoadingMore = true;
      context.read<ChatBloc>().add(const ChatLoadMoreRequested());
      Future.delayed(const Duration(seconds: 1), () => _isLoadingMore = false);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController
          .jumpTo(_scrollController.position.maxScrollExtent + 100);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Tin nhắn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            // Only jump to bottom on initial load
            if (_isInitialLoad) {
              _isInitialLoad = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom(animate: false);
              });
            }
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is ChatError) {
            return _buildError(state.message);
          }

          if (state is! ChatLoaded) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              // Messages list
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildMessageList(state),
              ),

              // Typing indicator
              TypingIndicator(
                typingNames: state.typingUsers.values.toList(),
              ),

              // Input bar
              ChatInputBar(
                onSend: (content) {
                  context.read<ChatBloc>().add(ChatSendMessage(
                        content: content,
                        senderId: _currentUserId,
                        senderName: _currentUserName,
                        senderAvatar: _currentUserAvatar,
                      ));
                  // Scroll down after sending with smooth animation
                  Future.delayed(const Duration(milliseconds: 150), () {
                    _scrollToBottom(animate: true);
                  });
                },
                onTypingStart: () {
                  context
                      .read<ChatBloc>()
                      .add(const ChatSendTyping(true));
                },
                onTypingStop: () {
                  context
                      .read<ChatBloc>()
                      .add(const ChatSendTyping(false));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageList(ChatLoaded state) {
    final messages = state.messages;
    final userId = _currentUserId;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: messages.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at top
          if (state.hasMore && index == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }

          final msgIndex = state.hasMore ? index - 1 : index;
          final message = messages[msgIndex];

          // System message
          if (message.isSystem) {
            return SystemMessage(content: message.content);
          }

          // Determine if we should show sender name (group chat, different sender than prev)
          bool showSender = false;
          if (msgIndex > 0) {
            final prev = messages[msgIndex - 1];
            showSender = prev.senderId != message.senderId && !prev.isSystem;
          } else {
            showSender = true;
          }

          return MessageBubble(
            message: message,
            currentUserId: userId,
            showSender: showSender,
          );
        },
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Hãy gửi tin nhắn đầu tiên!',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
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
          Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.danger.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text('Lỗi tải tin nhắn',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context
                  .read<ChatBloc>()
                  .add(ChatLoadRequested(widget.conversationId));
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
