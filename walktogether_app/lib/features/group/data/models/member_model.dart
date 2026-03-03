class MemberModel {
  final String id;
  final String fullName;
  final String? avatar;
  final String? email;
  final String? phone;
  final String role;

  MemberModel({
    required this.id,
    required this.fullName,
    this.avatar,
    this.email,
    this.phone,
    required this.role,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['_id'] as String,
      fullName: json['fullName'] as String,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'avatar': avatar,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}
