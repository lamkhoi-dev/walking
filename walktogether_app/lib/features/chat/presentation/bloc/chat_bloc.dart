import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../core/socket/socket_service.dart';

// ===== EVENTS =====
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

/// Load initial messages for a conversation
class ChatLoadRequested extends ChatEvent {
  final String conversationId;
  const ChatLoadRequested(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

/// Load more (older) messages
class ChatLoadMoreRequested extends ChatEvent {
  const ChatLoadMoreRequested();
}

/// Send a text message
class ChatSendMessage extends ChatEvent {
  final String content;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  const ChatSendMessage({
    required this.content,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
  });
  @override
  List<Object?> get props => [content, senderId, senderName];
}

/// A new message received via socket
class ChatMessageReceived extends ChatEvent {
  final MessageModel message;
  const ChatMessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

/// Typing indicator received
class ChatTypingReceived extends ChatEvent {
  final String userId;
  final String fullName;
  final bool isTyping;
  const ChatTypingReceived({
    required this.userId,
    required this.fullName,
    required this.isTyping,
  });
  @override
  List<Object?> get props => [userId, fullName, isTyping];
}

/// User is typing
class ChatSendTyping extends ChatEvent {
  final bool isTyping;
  const ChatSendTyping(this.isTyping);
  @override
  List<Object?> get props => [isTyping];
}

/// Mark conversation as read
class ChatMarkAsRead extends ChatEvent {
  const ChatMarkAsRead();
}

// ===== STATES =====
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final String conversationId;
  final List<MessageModel> messages;
  final bool hasMore;
  final int currentPage;
  final Map<String, String> typingUsers; // userId → fullName

  const ChatLoaded({
    required this.conversationId,
    required this.messages,
    this.hasMore = false,
    this.currentPage = 1,
    this.typingUsers = const {},
  });

  ChatLoaded copyWith({
    List<MessageModel>? messages,
    bool? hasMore,
    int? currentPage,
    Map<String, String>? typingUsers,
  }) {
    return ChatLoaded(
      conversationId: conversationId,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }

  @override
  List<Object?> get props =>
      [conversationId, messages, hasMore, currentPage, typingUsers];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  final SocketService _socketService;
  String? _currentConversationId;

  // Store specific callback references so off() only removes these
  void Function(dynamic)? _onNewMessageCallback;
  void Function(dynamic)? _onTypingCallback;

  ChatBloc({
    required ChatRepository repository,
    SocketService? socketService,
  })  : _repository = repository,
        _socketService = socketService ?? SocketService(),
        super(ChatInitial()) {
    on<ChatLoadRequested>(_onLoad);
    on<ChatLoadMoreRequested>(_onLoadMore);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatTypingReceived>(_onTypingReceived);
    on<ChatSendTyping>(_onSendTyping);
    on<ChatMarkAsRead>(_onMarkAsRead);
  }

  /// Setup socket listeners for a conversation
  void _setupSocketListeners() {
    _onNewMessageCallback = (data) {
      if (data is Map<String, dynamic>) {
        final message = MessageModel.fromJson(data);
        if (message.conversationId == _currentConversationId) {
          add(ChatMessageReceived(message));
        }
      }
    };

    _onTypingCallback = (data) {
      if (data is Map<String, dynamic> &&
          data['conversationId'] == _currentConversationId) {
        add(ChatTypingReceived(
          userId: data['userId'] as String? ?? '',
          fullName: data['fullName'] as String? ?? '',
          isTyping: data['isTyping'] as bool? ?? false,
        ));
      }
    };

    _socketService.on('chat:new_message', _onNewMessageCallback!);
    _socketService.on('chat:typing', _onTypingCallback!);
  }

  /// Remove socket listeners
  void _removeSocketListeners() {
    if (_onNewMessageCallback != null) {
      _socketService.off('chat:new_message', _onNewMessageCallback!);
      _onNewMessageCallback = null;
    }
    if (_onTypingCallback != null) {
      _socketService.off('chat:typing', _onTypingCallback!);
      _onTypingCallback = null;
    }
  }

  Future<void> _onLoad(
    ChatLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Leave previous conversation room if any
    if (_currentConversationId != null) {
      _socketService.leaveConversation(_currentConversationId!);
      _removeSocketListeners();
    }

    _currentConversationId = event.conversationId;
    emit(ChatLoading());

    try {
      final response = await _repository.getMessages(event.conversationId);

      // Join the conversation room
      _socketService.joinConversation(event.conversationId);
      _setupSocketListeners();

      // Mark as read
      _socketService.markAsRead(event.conversationId);

      emit(ChatLoaded(
        conversationId: event.conversationId,
        messages: response.messages.reversed.toList(), // oldest first
        hasMore: response.hasMore,
        currentPage: response.currentPage,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    ChatLoadMoreRequested event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded || !currentState.hasMore) return;

    try {
      final response = await _repository.getMessages(
        currentState.conversationId,
        page: currentState.currentPage + 1,
      );

      // Prepend older messages (server returns newest first, we reverse)
      final olderMessages = response.messages.reversed.toList();
      emit(currentState.copyWith(
        messages: [...olderMessages, ...currentState.messages],
        hasMore: response.hasMore,
        currentPage: response.currentPage,
      ));
    } catch (e) {
      // Silently fail for pagination
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Optimistic update — add message to list immediately
    final optimisticMessage = MessageModel.optimistic(
      conversationId: currentState.conversationId,
      senderId: event.senderId,
      senderName: event.senderName,
      senderAvatar: event.senderAvatar,
      content: event.content,
    );

    emit(currentState.copyWith(
      messages: [...currentState.messages, optimisticMessage],
    ));

    // Send via socket (preferred for real-time)
    if (_socketService.isConnected) {
      _socketService.sendMessage(
        conversationId: currentState.conversationId,
        content: event.content,
      );
    } else {
      // Fallback to REST
      try {
        await _repository.sendMessageRest(
          currentState.conversationId,
          content: event.content,
        );
      } catch (_) {}
    }
  }

  Future<void> _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Check if this message replaces an optimistic one
    final messages = currentState.messages.toList();
    final optimisticIndex = messages.indexWhere(
      (m) =>
          m.isSending &&
          m.senderId == event.message.senderId &&
          m.content == event.message.content,
    );

    if (optimisticIndex != -1) {
      // Replace optimistic with confirmed message
      messages[optimisticIndex] = event.message;
    } else {
      // Check for duplicate (same id)
      final exists = messages.any((m) => m.id == event.message.id);
      if (!exists) {
        messages.add(event.message);
      }
    }

    // Remove typing indicator for the sender
    final typingUsers = Map<String, String>.from(currentState.typingUsers);
    typingUsers.remove(event.message.senderId);

    emit(currentState.copyWith(
      messages: messages,
      typingUsers: typingUsers,
    ));

    // Auto-mark as read
    _socketService.markAsRead(currentState.conversationId);
  }

  Future<void> _onTypingReceived(
    ChatTypingReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final typingUsers = Map<String, String>.from(currentState.typingUsers);
    if (event.isTyping) {
      typingUsers[event.userId] = event.fullName;
    } else {
      typingUsers.remove(event.userId);
    }

    emit(currentState.copyWith(typingUsers: typingUsers));
  }

  Future<void> _onSendTyping(
    ChatSendTyping event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentConversationId != null) {
      _socketService.sendTyping(_currentConversationId!, event.isTyping);
    }
  }

  Future<void> _onMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentConversationId != null) {
      _socketService.markAsRead(_currentConversationId!);
    }
  }

  @override
  Future<void> close() {
    if (_currentConversationId != null) {
      _socketService.leaveConversation(_currentConversationId!);
    }
    _removeSocketListeners();
    return super.close();
  }
}
