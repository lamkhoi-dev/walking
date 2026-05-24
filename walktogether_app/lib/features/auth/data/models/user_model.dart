class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final String? avatar;
  final String role;
  final String? companyId;
  final String? companyCode;
  final bool isActive;
  final DateTime? lastOnline;
  final DateTime? createdAt;
  final int friendCount;
  final int postCount;
  final int groupCount;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    required this.fullName,
    this.avatar,
    required this.role,
    this.companyId,
    this.companyCode,
    this.isActive = true,
    this.lastOnline,
    this.createdAt,
    this.friendCount = 0,
    this.postCount = 0,
    this.groupCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'],
      phone: json['phone'],
      fullName: json['fullName'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'member',
      companyId: json['companyId'] is Map
          ? json['companyId']['_id']
          : json['companyId'],
      companyCode: json['companyCode'],
      isActive: json['isActive'] ?? true,
      lastOnline: json['lastOnline'] != null
          ? DateTime.tryParse(json['lastOnline'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      friendCount: json['friendCount'] ?? 0,
      postCount: json['postCount'] ?? 0,
      groupCount: json['groupCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'avatar': avatar,
      'role': role,
      'companyId': companyId,
      'companyCode': companyCode,
      'isActive': isActive,
      'lastOnline': lastOnline?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'friendCount': friendCount,
      'postCount': postCount,
      'groupCount': groupCount,
    };
  }

  /// Create a copy with updated social counts
  UserModel copyWithSocialCounts({
    int? friendCount,
    int? postCount,
    int? groupCount,
  }) {
    return UserModel(
      id: id,
      email: email,
      phone: phone,
      fullName: fullName,
      avatar: avatar,
      role: role,
      companyId: companyId,
      companyCode: companyCode,
      isActive: isActive,
      lastOnline: lastOnline,
      createdAt: createdAt,
      friendCount: friendCount ?? this.friendCount,
      postCount: postCount ?? this.postCount,
      groupCount: groupCount ?? this.groupCount,
    );
  }

  String get displayIdentifier => email ?? phone ?? '';
}
