import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../core/socket/socket_service.dart';

// ===== EVENTS =====
abstract class ConversationListEvent extends Equatable {
  const ConversationListEvent();
  @override
  List<Object?> get props => [];
}

class ConversationListLoadRequested extends ConversationListEvent {}

class ConversationListRefreshRequested extends ConversationListEvent {}

/// Triggered when a new message arrives via socket → update conversation order/preview
class ConversationListMessageReceived extends ConversationListEvent {
  final MessageModel message;
  final String conversationId;
  const ConversationListMessageReceived(this.conversationId, this.message);
  @override
  List<Object?> get props => [conversationId, message];
}

/// Triggered when a conversation is read
class ConversationListMarkRead extends ConversationListEvent {
  final String conversationId;
  const ConversationListMarkRead(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

/// When user starts a new DM
class ConversationListCreateDirect extends ConversationListEvent {
  final String userId;
  const ConversationListCreateDirect(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ===== STATES =====
abstract class ConversationListState extends Equatable {
  const ConversationListState();
  @override
  List<Object?> get props => [];
}

class ConversationListInitial extends ConversationListState {}

class ConversationListLoading extends ConversationListState {}

class ConversationListLoaded extends ConversationListState {
  final List<ConversationModel> conversations;
  const ConversationListLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class ConversationListError extends ConversationListState {
  final String message;
  const ConversationListError(this.message);
  @override
  List<Object?> get props => [message];
}

/// After creating a direct conversation — navigate to it
class ConversationListDirectCreated extends ConversationListState {
  final ConversationModel conversation;
  const ConversationListDirectCreated(this.conversation);
  @override
  List<Object?> get props => [conversation];
}

// ===== BLOC =====
class ConversationListBloc
    extends Bloc<ConversationListEvent, ConversationListState> {
  final ChatRepository _repository;
  final SocketService _socketService;
  StreamSubscription? _newMessageSub;
  void Function(dynamic)? _onNewMessageCallback;

  ConversationListBloc({
    required ChatRepository repository,
    SocketService? socketService,
  })  : _repository = repository,
        _socketService = socketService ?? SocketService(),
        super(ConversationListInitial()) {
    on<ConversationListLoadRequested>(_onLoad);
    on<ConversationListRefreshRequested>(_onRefresh);
    on<ConversationListMessageReceived>(_onMessageReceived);
    on<ConversationListMarkRead>(_onMarkRead);
    on<ConversationListCreateDirect>(_onCreateDirect);

    // Listen for incoming messages from socket to update conversation previews
    _onNewMessageCallback = (data) {
      if (data is Map<String, dynamic>) {
        final message = MessageModel.fromJson(data);
        add(ConversationListMessageReceived(message.conversationId, message));
      }
    };
    _socketService.on('chat:new_message', _onNewMessageCallback!);
  }

  Future<void> _onLoad(
    ConversationListLoadRequested event,
    Emitter<ConversationListState> emit,
  ) async {
    emit(ConversationListLoading());
    try {
      final conversations = await _repository.getConversations();
      emit(ConversationListLoaded(conversations));
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    ConversationListRefreshRequested event,
    Emitter<ConversationListState> emit,
  ) async {
    try {
      final conversations = await _repository.getConversations();
      emit(ConversationListLoaded(conversations));
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }

  Future<void> _onMessageReceived(
    ConversationListMessageReceived event,
    Emitter<ConversationListState> emit,
  ) async {
    // A new message came in — reload conversations to get updated last message + sort
    try {
      final conversations = await _repository.getConversations();
      emit(ConversationListLoaded(conversations));
    } catch (_) {
      // Silently fail — will catch up on next refresh
    }
  }

  Future<void> _onMarkRead(
    ConversationListMarkRead event,
    Emitter<ConversationListState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.conversationId);
      // Reload to update unread counts
      final conversations = await _repository.getConversations();
      emit(ConversationListLoaded(conversations));
    } catch (_) {}
  }

  Future<void> _onCreateDirect(
    ConversationListCreateDirect event,
    Emitter<ConversationListState> emit,
  ) async {
    try {
      final conversation =
          await _repository.getOrCreateDirectConversation(event.userId);
      emit(ConversationListDirectCreated(conversation));
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    if (_onNewMessageCallback != null) {
      _socketService.off('chat:new_message', _onNewMessageCallback!);
    }
    _newMessageSub?.cancel();
    return super.close();
  }
}
