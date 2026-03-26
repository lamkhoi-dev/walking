import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/post_model.dart';

class FeedRepository {
  final DioClient _dioClient;

  FeedRepository(this._dioClient);

  /// Get feed with visibility-aware filtering
  Future<FeedResponse> getFeed({
    String filter = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.postsFeed,
      queryParameters: {'filter': filter, 'page': page, 'limit': limit},
    );
    final data = response.data['data'] as List;
    final posts = data
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = response.data['pagination'] as Map<String, dynamic>?;

    return FeedResponse(
      posts: posts,
      page: pagination?['page'] as int? ?? page,
      totalPages: pagination?['pages'] as int? ?? 1,
      total: pagination?['total'] as int? ?? posts.length,
    );
  }

  /// Get a single post by ID
  Future<PostModel> getPostById(String postId) async {
    final response = await _dioClient.get(ApiEndpoints.postDetail(postId));
    return PostModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Create a new post (text or with images)
  Future<PostModel> createPost({
    required String content,
    String visibility = 'public',
    List<String>? visibleToGroupIds,
    List<File>? images,
    String? type,
    String? sharedPostId,
    String? sharedContestId,
    int? achievementRank,
    int? achievementSteps,
  }) async {
    final formData = FormData.fromMap({
      'content': content,
      'visibility': visibility,
      if (visibleToGroupIds != null && visibleToGroupIds.isNotEmpty)
        'visibleToGroups': visibleToGroupIds.join(','),
      if (type != null) 'type': type,
      if (sharedPostId != null) 'sharedPostId': sharedPostId,
      if (sharedContestId != null) 'sharedContestId': sharedContestId,
      if (achievementRank != null) 'achievementRank': achievementRank,
      if (achievementSteps != null) 'achievementSteps': achievementSteps,
    });

    if (images != null) {
      for (final image in images) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              image.path,
              filename: image.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }
    }

    final response = await _dioClient.post(
      ApiEndpoints.postsCreate,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return PostModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Toggle like on a post
  Future<LikeResponse> toggleLike(String postId) async {
    final response = await _dioClient.post(ApiEndpoints.postLike(postId));
    final data = response.data['data'] as Map<String, dynamic>;
    return LikeResponse(
      liked: data['liked'] as bool,
      likesCount: data['likesCount'] as int,
    );
  }

  /// Get comments for a post (paginated)
  Future<CommentsResponse> getComments(String postId, {int page = 1, int limit = 20}) async {
    final response = await _dioClient.get(
      ApiEndpoints.postComments(postId),
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] as List;
    final comments = data
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = response.data['pagination'] as Map<String, dynamic>?;

    return CommentsResponse(
      comments: comments,
      page: pagination?['page'] as int? ?? page,
      totalPages: pagination?['pages'] as int? ?? 1,
    );
  }

  /// Create a comment on a post
  Future<CommentModel> createComment(String postId, String content) async {
    final response = await _dioClient.post(
      ApiEndpoints.postComments(postId),
      data: {'content': content},
    );
    return CommentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _dioClient.delete(ApiEndpoints.deleteComment(commentId));
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    await _dioClient.delete(ApiEndpoints.postDetail(postId));
  }
}

class FeedResponse {
  final List<PostModel> posts;
  final int page;
  final int totalPages;
  final int total;

  FeedResponse({
    required this.posts,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => page < totalPages;
}

class LikeResponse {
  final bool liked;
  final int likesCount;

  LikeResponse({required this.liked, required this.likesCount});
}

class CommentsResponse {
  final List<CommentModel> comments;
  final int page;
  final int totalPages;

  CommentsResponse({
    required this.comments,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}
