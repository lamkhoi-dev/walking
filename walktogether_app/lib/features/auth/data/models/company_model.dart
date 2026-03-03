class CompanyModel {
  final String id;
  final String name;
  final String status;
  final String? code;
  final String? email;
  final String? phone;
  final String? logo;
  final String? address;
  final String? description;
  final int totalMembers;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.status,
    this.code,
    this.email,
    this.phone,
    this.logo,
    this.address,
    this.description,
    this.totalMembers = 0,
    this.updatedAt,
    this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['_id'] ?? json['companyId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'pending',
      code: json['code'],
      email: json['email'],
      phone: json['phone'],
      logo: json['logo'],
      address: json['address'],
      description: json['description'],
      totalMembers: json['totalMembers'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'status': status,
      'code': code,
      'email': email,
      'phone': phone,
      'logo': logo,
      'address': address,
      'description': description,
      'totalMembers': totalMembers,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';
}
