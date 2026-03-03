import 'member_model.dart';

class LastMessageInfo {
  final String content;
  final String type;
  final String? senderName;
  final DateTime createdAt;

  LastMessageInfo({
    required this.content,
    required this.type,
    this.senderName,
    required this.createdAt,
  });

  factory LastMessageInfo.fromJson(Map<String, dynamic> json) {
    return LastMessageInfo(
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      senderName: json['senderId'] is Map
          ? (json['senderId'] as Map<String, dynamic>)['fullName'] as String?
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String companyId;
  final String? createdById;
  final String? createdByName;
  final List<MemberModel> members;
  final int totalMembers;
  final String? conversationId;
  final LastMessageInfo? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.companyId,
    this.createdById,
    this.createdByName,
    this.members = const [],
    required this.totalMembers,
    this.conversationId,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    // Parse members
    List<MemberModel> members = [];
    if (json['members'] is List) {
      members = (json['members'] as List)
          .where((m) => m is Map<String, dynamic>)
          .map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    // Parse createdBy
    String? createdById;
    String? createdByName;
    if (json['createdBy'] is Map) {
      final cb = json['createdBy'] as Map<String, dynamic>;
      createdById = cb['_id'] as String?;
      createdByName = cb['fullName'] as String?;
    } else if (json['createdBy'] is String) {
      createdById = json['createdBy'] as String;
    }

    // Parse last message from conversation
    LastMessageInfo? lastMessage;
    if (json['conversationId'] is Map) {
      final conv = json['conversationId'] as Map<String, dynamic>;
      if (conv['lastMessage'] is Map) {
        lastMessage = LastMessageInfo.fromJson(
          conv['lastMessage'] as Map<String, dynamic>,
        );
      }
    }

    // conversationId can be a string or a map (populated)
    String? convId;
    if (json['conversationId'] is String) {
      convId = json['conversationId'] as String;
    } else if (json['conversationId'] is Map) {
      convId = (json['conversationId'] as Map<String, dynamic>)['_id'] as String?;
    }

    return GroupModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatar: json['avatar'] as String?,
      companyId: json['companyId'] is String
          ? json['companyId'] as String
          : (json['companyId'] as Map<String, dynamic>?)?['_id'] as String? ?? '',
      createdById: createdById,
      createdByName: createdByName,
      members: members,
      totalMembers: json['totalMembers'] as int? ?? members.length,
      conversationId: convId,
      lastMessage: lastMessage,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
