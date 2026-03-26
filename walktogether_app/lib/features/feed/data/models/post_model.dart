/// Post model matching server Post schema
class PostModel {
  final String id;
  final PostAuthor author;
  final String? companyId;
  final String visibility;
  final List<PostGroup> visibleToGroups;
  final String type;
  final String content;
  final List<PostMedia> media;
  final String? sharedPostId;
  final String? sharedContestId;
  final PostModel? sharedPost;
  final SharedContest? sharedContest;
  final int? achievementRank;
  final int? achievementSteps;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.author,
    this.companyId,
    this.visibility = 'public',
    this.visibleToGroups = const [],
    this.type = 'text',
    this.content = '',
    this.media = const [],
    this.sharedPostId,
    this.sharedContestId,
    this.sharedPost,
    this.sharedContest,
    this.achievementRank,
    this.achievementSteps,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final authorData = json['authorId'];
    final author = authorData is Map<String, dynamic>
        ? PostAuthor.fromJson(authorData)
        : PostAuthor(id: authorData?.toString() ?? '', fullName: 'Unknown', avatar: null);

    PostModel? sharedPost;
    if (json['sharedPostId'] is Map<String, dynamic>) {
      sharedPost = PostModel.fromJson(json['sharedPostId'] as Map<String, dynamic>);
    }

    SharedContest? sharedContest;
    if (json['sharedContestId'] is Map<String, dynamic>) {
      sharedContest = SharedContest.fromJson(json['sharedContestId'] as Map<String, dynamic>);
    }

    return PostModel(
      id: json['_id']?.toString() ?? '',
      author: author,
      companyId: json['companyId']?.toString(),
      visibility: json['visibility'] as String? ?? 'public',
      visibleToGroups: (json['visibleToGroups'] as List<dynamic>?)
              ?.map((g) => g is Map<String, dynamic>
                  ? PostGroup.fromJson(g)
                  : PostGroup(id: g.toString(), name: ''))
              .toList() ??
          [],
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      media: (json['media'] as List<dynamic>?)
              ?.map((m) => PostMedia.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      sharedPostId: json['sharedPostId'] is String ? json['sharedPostId'] as String : null,
      sharedContestId: json['sharedContestId'] is String
          ? json['sharedContestId'] as String
          : (json['sharedContestId'] is Map ? json['sharedContestId']['_id']?.toString() : null),
      sharedPost: sharedPost,
      sharedContest: sharedContest,
      achievementRank: json['achievementRank'] as int?,
      achievementSteps: json['achievementSteps'] as int?,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  PostModel copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return PostModel(
      id: id,
      author: author,
      companyId: companyId,
      visibility: visibility,
      visibleToGroups: visibleToGroups,
      type: type,
      content: content,
      media: media,
      sharedPostId: sharedPostId,
      sharedContestId: sharedContestId,
      sharedPost: sharedPost,
      sharedContest: sharedContest,
      achievementRank: achievementRank,
      achievementSteps: achievementSteps,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PostAuthor {
  final String id;
  final String fullName;
  final String? avatar;

  const PostAuthor({required this.id, required this.fullName, this.avatar});

  factory PostAuthor.fromJson(Map<String, dynamic> json) => PostAuthor(
        id: json['_id']?.toString() ?? '',
        fullName: json['fullName'] as String? ?? '',
        avatar: json['avatar'] as String?,
      );
}

class PostMedia {
  final String url;
  final String? publicId;
  final int width;
  final int height;

  const PostMedia({required this.url, this.publicId, this.width = 0, this.height = 0});

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
        url: json['url'] as String? ?? '',
        publicId: json['publicId'] as String?,
        width: json['width'] as int? ?? 0,
        height: json['height'] as int? ?? 0,
      );
}

class PostGroup {
  final String id;
  final String name;

  const PostGroup({required this.id, required this.name});

  factory PostGroup.fromJson(Map<String, dynamic> json) => PostGroup(
        id: json['_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

/// Shared contest data populated by server
class SharedContest {
  final String id;
  final String name;
  final String? description;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  const SharedContest({
    required this.id,
    required this.name,
    this.description,
    this.status = 'active',
    this.startDate,
    this.endDate,
  });

  factory SharedContest.fromJson(Map<String, dynamic> json) => SharedContest(
        id: json['_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        status: json['status'] as String? ?? 'active',
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'] as String)
            : null,
        endDate: json['endDate'] != null
            ? DateTime.tryParse(json['endDate'] as String)
            : null,
      );
}

class CommentModel {
  final String id;
  final String postId;
  final PostAuthor author;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final authorData = json['authorId'];
    final author = authorData is Map<String, dynamic>
        ? PostAuthor.fromJson(authorData)
        : PostAuthor(id: authorData?.toString() ?? '', fullName: 'Unknown', avatar: null);

    return CommentModel(
      id: json['_id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      author: author,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
