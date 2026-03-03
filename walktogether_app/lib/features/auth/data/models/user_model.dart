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
    };
  }

  String get displayIdentifier => email ?? phone ?? '';
}
