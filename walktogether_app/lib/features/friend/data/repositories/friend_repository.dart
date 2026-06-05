import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/friendship_model.dart';

/// Repository for friend-related API calls
class FriendRepository {
  final DioClient _dio;

  FriendRepository({required DioClient dio}) : _dio = dio;

  /// Send friend request
  Future<Map<String, dynamic>> sendRequest(String userId) async {
    final response = await _dio.post(ApiEndpoints.friendRequest(userId));
    return response.data;
  }

  /// Accept friend request
  Future<void> acceptRequest(String friendshipId) async {
    await _dio.put(ApiEndpoints.friendAccept(friendshipId));
  }

  /// Reject friend request (deletes record — allows re-send)
  Future<void> rejectRequest(String friendshipId) async {
    await _dio.put(ApiEndpoints.friendReject(friendshipId));
  }

  /// Cancel sent friend request
  Future<void> cancelRequest(String friendshipId) async {
    await _dio.delete(ApiEndpoints.friendCancel(friendshipId));
  }

  /// Unfriend
  Future<void> unfriend(String friendId) async {
    await _dio.delete(ApiEndpoints.unfriend(friendId));
  }

  /// Get friends list (paginated, searchable)
  Future<Map<String, dynamic>> getFriends({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dio.get(ApiEndpoints.friends, queryParameters: params);
    final data = response.data['data'] as Map<String, dynamic>;

    final friends = (data['friends'] as List<dynamic>)
        .map((f) => FriendUser.fromJson(f as Map<String, dynamic>))
        .toList();

    return {
      'friends': friends,
      'pagination': data['pagination'],
    };
  }

  /// Get incoming friend requests
  Future<Map<String, dynamic>> getFriendRequests({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.friendRequests,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] as Map<String, dynamic>;

    final requests = (data['requests'] as List<dynamic>)
        .map((r) => FriendRequest.fromJson(r as Map<String, dynamic>))
        .toList();

    return {
      'requests': requests,
      'pagination': data['pagination'],
    };
  }

  /// Get sent friend requests
  Future<Map<String, dynamic>> getSentRequests({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.friendSent,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] as Map<String, dynamic>;

    final requests = (data['requests'] as List<dynamic>)
        .map((r) => FriendRequest.fromJson(r as Map<String, dynamic>))
        .toList();

    return {
      'requests': requests,
      'pagination': data['pagination'],
    };
  }

  /// Get friendship status with a user
  Future<Map<String, dynamic>> getFriendshipStatus(String userId) async {
    final response = await _dio.get(ApiEndpoints.friendStatus(userId));
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Search users to add as friends
  Future<Map<String, dynamic>> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.friendSearch,
      queryParameters: {'q': query, 'page': page, 'limit': limit},
    );
    final data = response.data['data'] as Map<String, dynamic>;

    final users = (data['users'] as List<dynamic>)
        .map((u) => FriendUser.fromJson(u as Map<String, dynamic>))
        .toList();

    return {
      'users': users,
      'pagination': data['pagination'],
    };
  }

  /// Get friend count
  Future<int> getFriendCount([String? userId]) async {
    final endpoint = userId != null
        ? '${ApiEndpoints.friendCount}/$userId'
        : ApiEndpoints.friendCount;
    final response = await _dio.get(endpoint);
    return (response.data['data']['count'] as num?)?.toInt() ?? 0;
  }

  /// Get user profile (for viewing other users)
  Future<UserProfile> getUserProfile(String userId, {int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.userProfile(userId),
      queryParameters: {'page': page, 'limit': limit},
    );
    debugPrint('getUserProfile response: ${response.data}');
    final data = response.data['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }
}
