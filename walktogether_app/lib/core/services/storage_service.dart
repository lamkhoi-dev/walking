import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage service wrapping SharedPreferences for tokens and user data
class StorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _companyStatusKey = 'company_status';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) throw Exception('StorageService not initialized. Call init() first.');
    return _prefs!;
  }

  // === TOKEN MANAGEMENT ===

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _p.setString(_accessTokenKey, accessToken);
    await _p.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> saveAccessToken(String token) async {
    await _p.setString(_accessTokenKey, token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _p.setString(_refreshTokenKey, token);
  }

  Future<String?> getAccessToken() async => _p.getString(_accessTokenKey);
  Future<String?> getRefreshToken() async => _p.getString(_refreshTokenKey);

  Future<bool> hasToken() async => _p.containsKey(_accessTokenKey);

  // === USER DATA (JSON) ===

  Future<void> saveUserData(Map<String, dynamic> data) async {
    await _p.setString(_userDataKey, json.encode(data));
  }

  Map<String, dynamic>? getUserData() {
    final str = _p.getString(_userDataKey);
    if (str == null) return null;
    return json.decode(str) as Map<String, dynamic>;
  }

  // === COMPANY STATUS ===

  Future<void> saveCompanyStatus(String status) async {
    await _p.setString(_companyStatusKey, status);
  }

  String? getCompanyStatus() => _p.getString(_companyStatusKey);

  // === CLEAR ===

  Future<void> clearAll() async {
    await _p.clear();
  }

  Future<void> clearTokens() async {
    await _p.remove(_accessTokenKey);
    await _p.remove(_refreshTokenKey);
  }
}
