class RegisterRequest {
  final String? email;
  final String? phone;
  final String password;
  final String fullName;
  final String companyCode;

  RegisterRequest({
    this.email,
    this.phone,
    required this.password,
    required this.fullName,
    required this.companyCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'password': password,
      'fullName': fullName,
      'companyCode': companyCode,
    };
    if (email != null && email!.isNotEmpty) map['email'] = email;
    if (phone != null && phone!.isNotEmpty) map['phone'] = phone;
    return map;
  }
}
