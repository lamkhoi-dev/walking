import '../../../../core/network/dio_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';

class AuthRepository {
  final DioClient _dio;
  final StorageService _storage;

  AuthRepository({
    required DioClient dio,
    required StorageService storage,
  })  : _dio = dio,
        _storage = storage;

  /// Login with email/phone and password
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    final authResponse = AuthResponse.fromJson(response.data['data']);
    await _saveAuthData(authResponse);
    return authResponse;
  }

  /// Register a new member
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );
    final authResponse = AuthResponse.fromJson(response.data['data']);
    await _saveAuthData(authResponse);
    return authResponse;
  }

  /// Get current user profile
  Future<({UserModel user, CompanyModel? company})> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    final data = response.data['data'];
    final user = UserModel.fromJson(data['user']);
    final company = data['company'] != null
        ? CompanyModel.fromJson(data['company'])
        : null;
    return (user: user, company: company);
  }

  /// Get company status (for polling)
  Future<CompanyModel> getCompanyStatus() async {
    final response = await _dio.get(ApiEndpoints.companyStatus);
    return CompanyModel.fromJson(response.data['data']);
  }

  /// Refresh access token
  Future<String> refreshToken() async {
    final currentRefreshToken = await _storage.getRefreshToken();
    if (currentRefreshToken == null) {
      throw Exception('No refresh token');
    }

    final response = await _dio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': currentRefreshToken},
    );
    final newAccessToken = response.data['data']['accessToken'] as String;
    await _storage.saveAccessToken(newAccessToken);
    return newAccessToken;
  }

  /// Logout — clear local tokens
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network errors on logout
    }
    await clearTokens();
  }

  /// Save auth data to local storage
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _storage.saveAccessToken(authResponse.accessToken);
    await _storage.saveRefreshToken(authResponse.refreshToken);
    await _storage.saveUserData(authResponse.user.toJson());
    if (authResponse.company != null) {
      await _storage.saveCompanyStatus(authResponse.company!.status);
    }
  }

  /// Clear all saved tokens and user data
  Future<void> clearTokens() async {
    await _storage.clearAll();
  }

  /// Check if user has a valid token stored
  Future<bool> hasToken() async {
    return await _storage.hasToken();
  }
}
