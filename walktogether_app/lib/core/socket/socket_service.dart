import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_endpoints.dart';

/// Singleton Socket.IO service for real-time communication
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  io.Socket? get socket => _socket;

  /// Connect to the Socket.IO server with JWT token
  void connect(String token) {
    if (_socket != null && _isConnected) return;

    _socket = io.io(
      ApiEndpoints.baseUrl.replaceAll('/api/v1', ''),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(5000)
          .setReconnectionAttempts(10)
          .setAuth({'token': token})
          .setTimeout(90000) // Render cold start
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onConnectError((data) {
      _isConnected = false;
    });

    _socket!.onError((data) {
      _isConnected = false;
    });
  }

  /// Disconnect from Socket.IO
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Listen for an event
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Remove listener for an event. If callback is provided, only removes that specific listener.
  void off(String event, [Function(dynamic)? callback]) {
    if (callback != null) {
      _socket?.off(event, callback);
    } else {
      _socket?.off(event);
    }
  }

  /// Emit an event
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  /// Join a conversation room
  void joinConversation(String conversationId) {
    emit('chat:join', {'conversationId': conversationId});
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    emit('chat:leave', {'conversationId': conversationId});
  }

  /// Send a message via socket
  void sendMessage({
    required String conversationId,
    String type = 'text',
    required String content,
    String? imageUrl,
  }) {
    emit('chat:send_message', {
      'conversationId': conversationId,
      'type': type,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
  }

  /// Send typing indicator
  void sendTyping(String conversationId, bool isTyping) {
    emit('chat:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  /// Mark conversation as read
  void markAsRead(String conversationId) {
    emit('chat:read', {'conversationId': conversationId});
  }
}
