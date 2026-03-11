class RegisterRequest {
  final String? email;
  final String? phone;
  final String password;
  final String fullName;
  final String? companyCode;

  RegisterRequest({
    this.email,
    this.phone,
    required this.password,
    required this.fullName,
    this.companyCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'password': password,
      'fullName': fullName,
    };
    if (email != null && email!.isNotEmpty) map['email'] = email;
    if (phone != null && phone!.isNotEmpty) map['phone'] = phone;
    if (companyCode != null && companyCode!.isNotEmpty) {
      map['companyCode'] = companyCode;
    }
    return map;
  }
}
