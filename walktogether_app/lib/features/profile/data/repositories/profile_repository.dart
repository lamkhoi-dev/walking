import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

/// Personal statistics model
class PersonalStats {
  final TodayStats today;
  final PeriodStats week;
  final PeriodStats month;
  final AllTimeStats allTime;
  final int streak;

  PersonalStats({
    required this.today,
    required this.week,
    required this.month,
    required this.allTime,
    required this.streak,
  });

  factory PersonalStats.fromJson(Map<String, dynamic> json) {
    final month = PeriodStats.fromJson(json['month'] ?? {});
    
    // Fallback: if allTime is empty/missing, use month data
    AllTimeStats allTime;
    if (json['allTime'] != null && (json['allTime'] as Map).isNotEmpty) {
      allTime = AllTimeStats.fromJson(json['allTime']);
    } else {
      // Use month stats as fallback for allTime
      allTime = AllTimeStats(
        totalSteps: month.totalSteps,
        totalDistance: month.totalDistance,
        totalCalories: month.totalCalories,
        daysTracked: month.daysTracked,
        bestDay: null,
      );
    }
    
    return PersonalStats(
      today: TodayStats.fromJson(json['today'] ?? {}),
      week: PeriodStats.fromJson(json['week'] ?? {}),
      month: month,
      allTime: allTime,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class TodayStats {
  final int steps;
  final int distance;
  final double calories;

  TodayStats({
    required this.steps,
    required this.distance,
    required this.calories,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PeriodStats {
  final int totalSteps;
  final int totalDistance;
  final double totalCalories;
  final int avgStepsPerDay;
  final int daysTracked;

  PeriodStats({
    required this.totalSteps,
    required this.totalDistance,
    required this.totalCalories,
    required this.avgStepsPerDay,
    required this.daysTracked,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
      totalDistance: (json['totalDistance'] as num?)?.toInt() ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0.0,
      avgStepsPerDay: (json['avgStepsPerDay'] as num?)?.toInt() ?? 0,
      daysTracked: (json['daysTracked'] as num?)?.toInt() ?? 0,
    );
  }
}

class AllTimeStats {
  final int totalSteps;
  final int totalDistance;
  final double totalCalories;
  final int daysTracked;
  final BestDayStats? bestDay;

  AllTimeStats({
    required this.totalSteps,
    required this.totalDistance,
    required this.totalCalories,
    required this.daysTracked,
    this.bestDay,
  });

  factory AllTimeStats.fromJson(Map<String, dynamic> json) {
    return AllTimeStats(
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
      totalDistance: (json['totalDistance'] as num?)?.toInt() ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0.0,
      daysTracked: (json['daysTracked'] as num?)?.toInt() ?? 0,
      bestDay: json['bestDay'] != null
          ? BestDayStats.fromJson(json['bestDay'])
          : null,
    );
  }
}

class BestDayStats {
  final String date;
  final int steps;

  BestDayStats({required this.date, required this.steps});

  factory BestDayStats.fromJson(Map<String, dynamic> json) {
    return BestDayStats(
      date: json['date'] as String? ?? '',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Profile repository for user profile operations
class ProfileRepository {
  final DioClient _dio;

  ProfileRepository({required DioClient dio}) : _dio = dio;

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? avatar,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (avatar != null) data['avatar'] = avatar;

    final response = await _dio.put(ApiEndpoints.updateMe, data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Upload avatar image and update profile
  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'avatar.jpg',
      ),
    });

    final response = await _dio.post(
      ApiEndpoints.uploadAvatar,
      data: formData,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get personal statistics
  Future<PersonalStats> getStats() async {
    final response = await _dio.get(ApiEndpoints.myStats);
    debugPrint('ProfileRepository: raw response: ${response.data}');
    final data = response.data['data'] as Map<String, dynamic>;
    debugPrint('ProfileRepository: data to parse: $data');
    return PersonalStats.fromJson(data);
  }
}

