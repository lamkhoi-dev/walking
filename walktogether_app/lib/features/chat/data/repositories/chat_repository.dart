import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/conversation_model.dart';

/// Repository handling chat REST API calls.
/// Real-time messaging goes through [SocketService].
class ChatRepository {
  final DioClient _dioClient;

  ChatRepository(this._dioClient);

  /// Fetch all conversations for the current user
  Future<List<ConversationModel>> getConversations() async {
    final response = await _dioClient.get(ApiEndpoints.conversations);
    final data = response.data['data'] as List;
    return data
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get or create a direct conversation with another user
  Future<ConversationModel> getOrCreateDirectConversation(String userId) async {
    final response = await _dioClient.post(
      ApiEndpoints.conversationDirect,
      data: {'userId': userId},
    );
    return ConversationModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Fetch messages for a conversation (paginated)
  Future<MessagesResponse> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.messages(conversationId),
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] as List;
    final messages = data
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final pagination = response.data['pagination'] as Map<String, dynamic>?;

    return MessagesResponse(
      messages: messages,
      currentPage: pagination?['page'] as int? ?? page,
      totalPages: pagination?['pages'] as int? ?? 1,
      total: pagination?['total'] as int? ?? messages.length,
    );
  }

  /// Send a message via REST (fallback when socket is unavailable)
  Future<MessageModel> sendMessageRest(
    String conversationId, {
    required String content,
    String type = 'text',
    String? imageUrl,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.messages(conversationId),
      data: {
        'content': content,
        'type': type,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
    return MessageModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Mark a conversation as read via REST
  Future<void> markAsRead(String conversationId) async {
    await _dioClient.put(ApiEndpoints.conversationRead(conversationId));
  }

  /// Upload an image to a conversation
  Future<MessageModel> uploadImage(
    String conversationId,
    File imageFile,
  ) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _dioClient.post(
      ApiEndpoints.conversationUpload(conversationId),
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return MessageModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
  /// Share a post to group chat(s)
  Future<Map<String, dynamic>> sharePostToGroups({
    required String postId,
    required List<String> groupIds,
    String? content,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.sharePost,
      data: {
        'postId': postId,
        'groupIds': groupIds,
        if (content != null && content.isNotEmpty) 'content': content,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}

/// Response wrapper for paginated messages
class MessagesResponse {
  final List<MessageModel> messages;
  final int currentPage;
  final int totalPages;
  final int total;

  MessagesResponse({
    required this.messages,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => currentPage < totalPages;
}
