/// Model for a contest (group step competition)
class ContestModel {
  final String id;
  final String name;
  final String description;
  final String groupId;
  final String? groupName;
  final String? groupAvatar;
  final String companyId;
  final String? createdById;
  final String? createdByName;
  final String? createdByAvatar;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // upcoming, active, completed, cancelled
  final List<ParticipantInfo> participants;
  final DateTime createdAt;

  ContestModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.groupId,
    this.groupName,
    this.groupAvatar,
    required this.companyId,
    this.createdById,
    this.createdByName,
    this.createdByAvatar,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.participants = const [],
    required this.createdAt,
  });

  factory ContestModel.fromJson(Map<String, dynamic> json) {
    // Parse group info
    String groupId;
    String? groupName;
    String? groupAvatar;
    if (json['groupId'] is Map) {
      final g = json['groupId'] as Map<String, dynamic>;
      groupId = g['_id'] as String? ?? '';
      groupName = g['name'] as String?;
      groupAvatar = g['avatar'] as String?;
    } else {
      groupId = json['groupId'] as String? ?? '';
    }

    // Parse createdBy info
    String? createdById;
    String? createdByName;
    String? createdByAvatar;
    if (json['createdBy'] is Map) {
      final cb = json['createdBy'] as Map<String, dynamic>;
      createdById = cb['_id'] as String?;
      createdByName = cb['fullName'] as String?;
      createdByAvatar = cb['avatar'] as String?;
    } else if (json['createdBy'] is String) {
      createdById = json['createdBy'] as String;
    }

    // Parse participants
    List<ParticipantInfo> participants = [];
    if (json['participants'] is List) {
      participants = (json['participants'] as List)
          .where((p) => p is Map<String, dynamic>)
          .map((p) => ParticipantInfo.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return ContestModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      groupId: groupId,
      groupName: groupName,
      groupAvatar: groupAvatar,
      companyId: json['companyId'] as String? ?? '',
      createdById: createdById,
      createdByName: createdByName,
      createdByAvatar: createdByAvatar,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String? ?? 'upcoming',
      participants: participants,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Whether the current user can cancel this contest
  bool get isCancellable => status == 'upcoming' || status == 'active';

  /// Whether the contest can be updated
  bool get isEditable => status == 'upcoming';

  /// Whether the contest is currently running
  bool get isActive => status == 'active';

  /// Whether the contest has ended
  bool get isFinished => status == 'completed' || status == 'cancelled';
}

class ParticipantInfo {
  final String id;
  final String fullName;
  final String? avatar;

  ParticipantInfo({
    required this.id,
    required this.fullName,
    this.avatar,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      id: json['_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatar: json['avatar'] as String?,
    );
  }
}
