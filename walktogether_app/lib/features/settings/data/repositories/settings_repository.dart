import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

/// User settings model
class UserSettings {
  final int dailyGoalSteps;
  final NotificationSettings notifications;
  final String units;

  const UserSettings({
    this.dailyGoalSteps = 10000,
    this.notifications = const NotificationSettings(),
    this.units = 'metric',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      dailyGoalSteps: (json['dailyGoalSteps'] as num?)?.toInt() ?? 10000,
      notifications: json['notifications'] != null
          ? NotificationSettings.fromJson(json['notifications'])
          : const NotificationSettings(),
      units: json['units'] as String? ?? 'metric',
    );
  }

  UserSettings copyWith({
    int? dailyGoalSteps,
    NotificationSettings? notifications,
    String? units,
  }) {
    return UserSettings(
      dailyGoalSteps: dailyGoalSteps ?? this.dailyGoalSteps,
      notifications: notifications ?? this.notifications,
      units: units ?? this.units,
    );
  }
}

class NotificationSettings {
  final bool chat;
  final bool contest;
  final bool dailyGoal;
  final bool weeklyReport;

  const NotificationSettings({
    this.chat = true,
    this.contest = true,
    this.dailyGoal = true,
    this.weeklyReport = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      chat: json['chat'] as bool? ?? true,
      contest: json['contest'] as bool? ?? true,
      dailyGoal: json['dailyGoal'] as bool? ?? true,
      weeklyReport: json['weeklyReport'] as bool? ?? true,
    );
  }

  NotificationSettings copyWith({
    bool? chat,
    bool? contest,
    bool? dailyGoal,
    bool? weeklyReport,
  }) {
    return NotificationSettings(
      chat: chat ?? this.chat,
      contest: contest ?? this.contest,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      weeklyReport: weeklyReport ?? this.weeklyReport,
    );
  }

  Map<String, dynamic> toJson() => {
        'chat': chat,
        'contest': contest,
        'dailyGoal': dailyGoal,
        'weeklyReport': weeklyReport,
      };
}

/// Repository for settings API calls
class SettingsRepository {
  final DioClient _dio;

  SettingsRepository({required DioClient dio}) : _dio = dio;

  /// Get current user settings
  Future<UserSettings> getSettings() async {
    final response = await _dio.get(ApiEndpoints.settings);
    debugPrint('SettingsRepository: raw response: ${response.data}');
    final data = response.data['data'] as Map<String, dynamic>;
    return UserSettings.fromJson(data);
  }

  /// Update user settings (partial update)
  Future<UserSettings> updateSettings({
    int? dailyGoalSteps,
    NotificationSettings? notifications,
    String? units,
  }) async {
    final body = <String, dynamic>{};
    if (dailyGoalSteps != null) body['dailyGoalSteps'] = dailyGoalSteps;
    if (notifications != null) body['notifications'] = notifications.toJson();
    if (units != null) body['units'] = units;

    final response = await _dio.put(ApiEndpoints.settings, data: body);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserSettings.fromJson(data);
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Delete (soft) user account
  Future<void> deleteAccount(String password) async {
    await _dio.delete(
      ApiEndpoints.deleteAccount,
      data: {'password': password},
    );
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    await _dio.post(ApiEndpoints.blockUser(userId));
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    await _dio.delete(ApiEndpoints.unblockUser(userId));
  }

  /// Get list of blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final response = await _dio.get(ApiEndpoints.blockedUsers);
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Report content (post, comment, or user)
  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    await _dio.post(
      ApiEndpoints.reports,
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
  }
}
