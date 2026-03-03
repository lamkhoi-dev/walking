import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

/// Repository for step-related REST API calls
class StepRepository {
  final DioClient _dioClient;

  StepRepository(this._dioClient);

  /// Sync steps to server via REST
  Future<Map<String, dynamic>> syncSteps({
    required String date,
    required int steps,
    Map<String, int>? hourlySteps,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.stepSync,
      data: {
        'date': date,
        'steps': steps,
        if (hourlySteps != null) 'hourlySteps': hourlySteps,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get today's step data
  Future<StepTodayData> getToday() async {
    final response = await _dioClient.get(ApiEndpoints.stepToday);
    final data = response.data['data'] as Map<String, dynamic>;
    return StepTodayData.fromJson(data);
  }

  /// Get step history in a date range
  Future<List<StepDayRecord>> getHistory({
    String? from,
    String? to,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.stepHistory,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    final data = response.data['data'] as List;
    return data
        .map((e) => StepDayRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get step statistics (today, week, month)
  Future<StepStatsData> getStats() async {
    final response = await _dioClient.get(ApiEndpoints.stepStats);
    final data = response.data['data'] as Map<String, dynamic>;
    return StepStatsData.fromJson(data);
  }
}

/// Today's step data from server
class StepTodayData {
  final int steps;
  final int distance;
  final double calories;
  final String date;

  StepTodayData({
    required this.steps,
    required this.distance,
    required this.calories,
    required this.date,
  });

  factory StepTodayData.fromJson(Map<String, dynamic> json) {
    return StepTodayData(
      steps: json['steps'] as int? ?? 0,
      distance: json['distance'] as int? ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
    );
  }
}

/// A single day's step record
class StepDayRecord {
  final String id;
  final String date;
  final int steps;
  final int distance;
  final double calories;
  final Map<String, int> hourlySteps;

  StepDayRecord({
    required this.id,
    required this.date,
    required this.steps,
    required this.distance,
    required this.calories,
    required this.hourlySteps,
  });

  factory StepDayRecord.fromJson(Map<String, dynamic> json) {
    Map<String, int> hourly = {};
    if (json['hourlySteps'] is Map) {
      hourly = (json['hourlySteps'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    }

    return StepDayRecord(
      id: json['_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      steps: json['steps'] as int? ?? 0,
      distance: json['distance'] as int? ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      hourlySteps: hourly,
    );
  }
}

/// Step statistics from server
class StepStatsData {
  final StepPeriodStats today;
  final StepPeriodStats week;
  final StepPeriodStats month;

  StepStatsData({
    required this.today,
    required this.week,
    required this.month,
  });

  factory StepStatsData.fromJson(Map<String, dynamic> json) {
    return StepStatsData(
      today: StepPeriodStats.fromJson(
        json['today'] as Map<String, dynamic>? ?? {},
        isToday: true,
      ),
      week: StepPeriodStats.fromJson(
        json['week'] as Map<String, dynamic>? ?? {},
      ),
      month: StepPeriodStats.fromJson(
        json['month'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class StepPeriodStats {
  final int totalSteps;
  final int totalDistance;
  final double totalCalories;
  final int avgStepsPerDay;
  final int daysTracked;

  StepPeriodStats({
    required this.totalSteps,
    required this.totalDistance,
    required this.totalCalories,
    required this.avgStepsPerDay,
    required this.daysTracked,
  });

  factory StepPeriodStats.fromJson(Map<String, dynamic> json, {bool isToday = false}) {
    if (isToday) {
      return StepPeriodStats(
        totalSteps: json['steps'] as int? ?? 0,
        totalDistance: json['distance'] as int? ?? 0,
        totalCalories: (json['calories'] as num?)?.toDouble() ?? 0.0,
        avgStepsPerDay: json['steps'] as int? ?? 0,
        daysTracked: 1,
      );
    }
    return StepPeriodStats(
      totalSteps: json['totalSteps'] as int? ?? 0,
      totalDistance: json['totalDistance'] as int? ?? 0,
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0.0,
      avgStepsPerDay: json['avgStepsPerDay'] as int? ?? 0,
      daysTracked: json['daysTracked'] as int? ?? 0,
    );
  }
}
