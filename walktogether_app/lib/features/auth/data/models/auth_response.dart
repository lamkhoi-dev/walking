import 'user_model.dart';
import 'company_model.dart';

class AuthResponse {
  final UserModel user;
  final CompanyModel? company;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    this.company,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      company: json['company'] != null
          ? CompanyModel.fromJson(json['company'])
          : null,
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }
}
