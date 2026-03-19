/// API endpoints configuration
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - change for production
  // static const String baseUrl = 'http://10.0.2.2:5000/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api/v1'; // iOS simulator
  static const String baseUrl = 'https://walktogether-api.onrender.com/api/v1'; // Production

  // === AUTH ===
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateMe = '/auth/me';
  static const String myStats = '/auth/me/stats';

  // === COMPANY ===
  static const String companyRegister = '/companies/register';
  static const String companyStatus = '/companies/status';
  static const String companyProfile = '/companies/profile';
  static const String companyMembers = '/companies/members';

  // === ADMIN (Super Admin) ===
  static const String adminCompanies = '/admin/companies';
  static String adminCompanyAction(String id) => '/admin/companies/$id';

  // === GROUPS ===
  static const String groups = '/groups';
  static String groupDetail(String id) => '/groups/$id';
  static String groupMembers(String id) => '/groups/$id/members';
  static String groupJoin(String id) => '/groups/join/$id';

  // === CHAT ===
  static const String conversations = '/chat/conversations';
  static const String conversationDirect = '/chat/conversations/direct';
  static String messages(String conversationId) => '/chat/conversations/$conversationId/messages';
  static String conversationRead(String conversationId) => '/chat/conversations/$conversationId/read';
  static String conversationUpload(String conversationId) => '/chat/conversations/$conversationId/upload';

  // === CONTESTS ===
  static const String contests = '/contests';
  static String contestDetail(String id) => '/contests/$id';
  static String contestLeaderboard(String id) => '/contests/$id/leaderboard';
  static String contestActiveByGroup(String groupId) => '/contests/group/$groupId/active';

  // === STEPS ===
  static const String stepSync = '/steps/sync';
  static const String stepToday = '/steps/today';
  static const String stepHistory = '/steps/history';
  static const String stepStats = '/steps/stats';

  // === SETTINGS ===
  static const String settings = '/settings';
  static const String changePassword = '/auth/change-password';
}
