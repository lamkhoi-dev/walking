class ConversationModel {
  final String id;
  final String type; // 'group' or 'direct'
  final String? groupId;
  final String? groupName;
  final String? groupAvatar;
  final int? groupTotalMembers;
  final List<ParticipantModel> participants;
  final MessageModel? lastMessage;
  final String? companyId;
  final bool isActive;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.type,
    this.groupId,
    this.groupName,
    this.groupAvatar,
    this.groupTotalMembers,
    this.participants = const [],
    this.lastMessage,
    this.companyId,
    this.isActive = true,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name: group name for group chats, other user's name for DMs
  String displayName(String currentUserId) {
    if (type == 'group' && groupName != null) {
      return groupName!;
    }
    // For direct, return the other participant's name
    final other = participants.where((p) => p.id != currentUserId).firstOrNull;
    return other?.fullName ?? 'Hội thoại';
  }

  /// Display avatar for the conversation
  String? displayAvatar(String currentUserId) {
    if (type == 'group') return groupAvatar;
    final other = participants.where((p) => p.id != currentUserId).firstOrNull;
    return other?.avatar;
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Parse participants
    List<ParticipantModel> participants = [];
    if (json['participants'] is List) {
      participants = (json['participants'] as List)
          .whereType<Map<String, dynamic>>()
          .map((p) => ParticipantModel.fromJson(p))
          .toList();
    }

    // Parse lastMessage
    MessageModel? lastMessage;
    if (json['lastMessage'] is Map<String, dynamic>) {
      lastMessage = MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>);
    }

    // Parse groupId (can be populated or just a string)
    String? groupId;
    String? groupName;
    String? groupAvatar;
    int? groupTotalMembers;
    if (json['groupId'] is Map<String, dynamic>) {
      final g = json['groupId'] as Map<String, dynamic>;
      groupId = g['_id'] as String?;
      groupName = g['name'] as String?;
      groupAvatar = g['avatar'] as String?;
      groupTotalMembers = g['totalMembers'] as int?;
    } else if (json['groupId'] is String) {
      groupId = json['groupId'] as String;
    }

    return ConversationModel(
      id: json['_id'] as String,
      type: json['type'] as String? ?? 'direct',
      groupId: groupId,
      groupName: groupName,
      groupAvatar: groupAvatar,
      groupTotalMembers: groupTotalMembers,
      participants: participants,
      lastMessage: lastMessage,
      companyId: json['companyId'] is String
          ? json['companyId'] as String
          : (json['companyId'] as Map<String, dynamic>?)?['_id'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ParticipantModel {
  final String id;
  final String fullName;
  final String? avatar;
  final String? email;
  final String? phone;
  final DateTime? lastOnline;

  ParticipantModel({
    required this.id,
    required this.fullName,
    this.avatar,
    this.email,
    this.phone,
    this.lastOnline,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['_id'] as String,
      fullName: json['fullName'] as String? ?? '',
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      lastOnline: json['lastOnline'] != null
          ? DateTime.tryParse(json['lastOnline'] as String)
          : null,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;
  final String type; // 'text', 'image', 'system', 'shared_post'
  final String content;
  final String? imageUrl;
  final String? sharedPostId;
  final SharedPostData? sharedPost;
  final List<String> readBy;
  final DateTime createdAt;

  // Local-only fields
  final bool isSending;

  MessageModel({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.imageUrl,
    this.sharedPostId,
    this.sharedPost,
    this.readBy = const [],
    required this.createdAt,
    this.isSending = false,
  });

  bool isMine(String currentUserId) => senderId == currentUserId;
  bool get isSystem => type == 'system';
  bool get isImage => type == 'image';
  bool get isSharedPost => type == 'shared_post';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Parse senderId (can be populated or just a string)
    String? senderId;
    String? senderName;
    String? senderAvatar;
    if (json['senderId'] is Map<String, dynamic>) {
      final s = json['senderId'] as Map<String, dynamic>;
      senderId = s['_id'] as String?;
      senderName = s['fullName'] as String?;
      senderAvatar = s['avatar'] as String?;
    } else if (json['senderId'] is String) {
      senderId = json['senderId'] as String;
    }

    // Parse readBy
    List<String> readBy = [];
    if (json['readBy'] is List) {
      readBy = (json['readBy'] as List).map((e) => e.toString()).toList();
    }

    // Parse sharedPostId
    String? sharedPostId;
    SharedPostData? sharedPost;
    if (json['sharedPostId'] is Map<String, dynamic>) {
      final sp = json['sharedPostId'] as Map<String, dynamic>;
      sharedPostId = sp['_id'] as String?;
      sharedPost = SharedPostData.fromJson(sp);
    } else if (json['sharedPostId'] is String) {
      sharedPostId = json['sharedPostId'] as String;
    }

    return MessageModel(
      id: json['_id'] as String,
      conversationId: json['conversationId'] is String
          ? json['conversationId'] as String
          : (json['conversationId'] as Map<String, dynamic>?)?['_id'] as String? ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      sharedPostId: sharedPostId,
      sharedPost: sharedPost,
      readBy: readBy,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Create a local optimistic message (before server confirms)
  factory MessageModel.optimistic({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    String type = 'text',
    String? imageUrl,
  }) {
    return MessageModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      content: content,
      imageUrl: imageUrl,
      readBy: [senderId],
      createdAt: DateTime.now(),
      isSending: true,
    );
  }
}

/// Lightweight model for shared post preview in chat
class SharedPostData {
  final String id;
  final String content;
  final String? authorName;
  final String? authorAvatar;
  final List<String> media;
  final String type;

  SharedPostData({
    required this.id,
    required this.content,
    this.authorName,
    this.authorAvatar,
    this.media = const [],
    this.type = 'text',
  });

  factory SharedPostData.fromJson(Map<String, dynamic> json) {
    String? authorName;
    String? authorAvatar;
    if (json['authorId'] is Map<String, dynamic>) {
      final a = json['authorId'] as Map<String, dynamic>;
      authorName = a['fullName'] as String?;
      authorAvatar = a['avatar'] as String?;
    }

    List<String> media = [];
    if (json['media'] is List) {
      media = (json['media'] as List)
          .map((e) => e is Map<String, dynamic> ? (e['url'] as String? ?? '') : e.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return SharedPostData(
      id: json['_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      authorName: authorName,
      authorAvatar: authorAvatar,
      media: media,
      type: json['type'] as String? ?? 'text',
    );
  }
}
