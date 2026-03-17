import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for counting steps using device pedometer sensor.
/// Stores data per-user in Hive for offline resilience.
class StepCounterService {
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  static const String _boxPrefix = 'step_counter_';
  static const String _keyBaseline = 'baseline_steps';
  static const String _keyLastSensorSteps = 'last_sensor_steps';
  static const String _keyTodaySteps = 'today_steps';
  static const String _keyTrackingDate = 'tracking_date';
  static const String _keyHourlySteps = 'hourly_steps';
  static const String _keyIsTracking = 'is_tracking';
  static const String _keyDailyGoal = 'daily_goal';
  static const String _keyGoalHistory = 'goal_history'; // date → {steps, goal, achieved}
  static const String _keyStreak = 'current_streak';

  late final Pedometer _pedometer = Pedometer();
  Box? _box;
  String? _currentUserId;
  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  bool _isInitialized = false;
  bool _isTracking = false;

  // Streams for UI updates
  final _stepController = StreamController<int>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<int> get stepStream => _stepController.stream;
  Stream<String> get statusStream => _statusController.stream;

  bool get isTracking => _isTracking;
  int get todaySteps => _box?.get(_keyTodaySteps, defaultValue: 0) ?? 0;
  String? get currentUserId => _currentUserId;

  /// Get the user's daily step goal (default 10000)
  int get dailyGoal => _box?.get(_keyDailyGoal, defaultValue: 10000) ?? 10000;

  /// Set the user's daily step goal
  Future<void> setDailyGoal(int goal) async {
    await _box?.put(_keyDailyGoal, goal);
  }

  /// Get current streak (consecutive days meeting goal)
  int get currentStreak => _box?.get(_keyStreak, defaultValue: 0) ?? 0;

  /// Get goal history map: { "YYYY-MM-DD": { "steps": int, "goal": int, "achieved": bool } }
  Map<String, dynamic> get goalHistory {
    final raw = _box?.get(_keyGoalHistory);
    if (raw is Map) {
      return Map<String, dynamic>.from(
        raw.map((k, v) => MapEntry(k.toString(), v is Map ? Map<String, dynamic>.from(v) : v)),
      );
    }
    return {};
  }

  /// Get hourly steps map (hour string → step count)
  Map<String, int> get hourlySteps {
    final raw = _box?.get(_keyHourlySteps);
    if (raw is Map) {
      return Map<String, int>.from(raw);
    }
    return {};
  }

  /// Initialize Hive box for step storage (no user context yet)
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Switch to a user-specific Hive box. Call on login.
  Future<void> switchUser(String userId) async {
    // If same user, no-op
    if (_currentUserId == userId && _box != null && _box!.isOpen) return;

    // Stop tracking & close previous box
    await stopTracking();
    await _box?.close();

    _currentUserId = userId;
    final boxName = '$_boxPrefix$userId';
    _box = await Hive.openBox(boxName);

    // Check if date changed (midnight reset)
    _checkDateReset();

    // Restore tracking state
    _isTracking = _box?.get(_keyIsTracking, defaultValue: false) ?? false;

    // Emit current steps to listeners
    _stepController.add(todaySteps);

    debugPrint('Step counter switched to user: $userId (box: $boxName)');
  }

  /// Detach from current user (on logout). Stops tracking, closes box, but preserves data.
  Future<void> detachUser() async {
    await stopTracking();
    // Save end-of-day record before detaching
    _saveGoalRecord();
    await _box?.close();
    _box = null;
    _currentUserId = null;
    _isTracking = false;
    _stepController.add(0);
    debugPrint('Step counter detached from user');
  }

  /// Start step tracking
  Future<void> startTracking() async {
    if (_box == null || !_box!.isOpen) {
      debugPrint('Cannot start tracking: no user box open');
      return;
    }
    if (_isTracking) return;

    // Request ACTIVITY_RECOGNITION permission (required on Android 10+)
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        debugPrint('ACTIVITY_RECOGNITION permission denied: $status');
        throw Exception('Cần cấp quyền nhận diện hoạt động để đếm bước chân');
      }
    }

    if (Platform.isIOS) {
      final status = await Permission.sensors.request();
      if (!status.isGranted) {
        debugPrint('Motion permission denied on iOS: $status');
        throw Exception('Cần cấp quyền truy cập cảm biến để đếm số bước chân');
      }
    }

    _isTracking = true;
    await _box?.put(_keyIsTracking, true);

    // Listen to step count events
    _stepSubscription = _pedometer.stepCountStream().listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: false,
    );

    // Listen to pedestrian status
    _statusSubscription = _pedometer.pedestrianStatusStream().listen(
      _onPedestrianStatus,
      onError: (e) {
        debugPrint('Pedestrian status error: $e');
        _statusController.add('unknown');
      },
      cancelOnError: false,
    );

    debugPrint('Step tracking started');
  }

  /// Stop step tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    await _box?.put(_keyIsTracking, false);

    await _stepSubscription?.cancel();
    _stepSubscription = null;
    await _statusSubscription?.cancel();
    _statusSubscription = null;

    debugPrint('Step tracking stopped');
  }

  /// Handle incoming step count from sensor
  void _onStepCount(int sensorSteps) {
    if (_box == null || !_box!.isOpen) return;

    // Check date reset first
    _checkDateReset();

    final baseline = (_box?.get(_keyBaseline, defaultValue: 0) ?? 0) as int;
    final lastSensor = (_box?.get(_keyLastSensorSteps, defaultValue: 0) ?? 0) as int;

    // Detect device reboot: sensor steps < last known sensor steps
    if (sensorSteps < lastSensor && lastSensor > 0) {
      // Device rebooted — set new baseline
      debugPrint('Device reboot detected. Resetting baseline.');
      final currentToday = todaySteps;
      _box?.put(_keyBaseline, sensorSteps - currentToday);
      _box?.put(_keyLastSensorSteps, sensorSteps);
      return;
    }

    // First reading — set baseline
    if (baseline == 0 && lastSensor == 0) {
      _box?.put(_keyBaseline, sensorSteps);
      _box?.put(_keyLastSensorSteps, sensorSteps);
      return;
    }

    // Calculate today's steps
    final steps = sensorSteps - baseline;
    final clampedSteps = steps < 0 ? 0 : steps;

    _box?.put(_keyTodaySteps, clampedSteps);
    _box?.put(_keyLastSensorSteps, sensorSteps);

    // Update hourly breakdown
    _updateHourlySteps(clampedSteps);

    // Emit to listeners
    _stepController.add(clampedSteps);
  }

  void _onStepCountError(dynamic error) {
    debugPrint('Step count error: $error');
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _statusController.add(event.name); // "walking", "stopped", "unknown"
  }

  /// Update hourly step breakdown
  void _updateHourlySteps(int totalSteps) {
    final hour = DateTime.now().hour.toString().padLeft(2, '0');
    final hourly = hourlySteps;
    hourly[hour] = totalSteps; // cumulative for the day up to this hour
    _box?.put(_keyHourlySteps, hourly);
  }

  /// Save a goal record for today (called at date reset or user detach)
  void _saveGoalRecord() {
    if (_box == null || !_box!.isOpen) return;
    final date = _todayDateStr();
    final steps = todaySteps;
    final goal = dailyGoal;
    final achieved = steps >= goal;

    final history = goalHistory;
    history[date] = {'steps': steps, 'goal': goal, 'achieved': achieved};

    // Keep only last 90 days
    if (history.length > 90) {
      final sortedKeys = history.keys.toList()..sort();
      for (final key in sortedKeys.take(history.length - 90)) {
        history.remove(key);
      }
    }

    _box?.put(_keyGoalHistory, history);

    // Update streak
    _updateStreak(history);
  }

  /// Calculate current consecutive-day goal streak
  void _updateStreak(Map<String, dynamic> history) {
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final record = history[dateStr];

      if (record is Map && record['achieved'] == true) {
        streak++;
      } else if (i == 0) {
        // Today not yet achieved is OK — don't break streak
        continue;
      } else {
        break;
      }
    }

    _box?.put(_keyStreak, streak);
  }

  /// Check if a new day has started → reset baseline
  void _checkDateReset() {
    final today = _todayDateStr();
    final storedDate = _box?.get(_keyTrackingDate, defaultValue: '') ?? '';

    if (storedDate != today) {
      debugPrint('New day detected: $storedDate → $today. Resetting steps.');

      // Save yesterday's goal record before resetting
      if (storedDate.isNotEmpty) {
        final yesterdaySteps = todaySteps;
        final goal = dailyGoal;
        final history = goalHistory;
        history[storedDate] = {
          'steps': yesterdaySteps,
          'goal': goal,
          'achieved': yesterdaySteps >= goal,
        };
        if (history.length > 90) {
          final sortedKeys = history.keys.toList()..sort();
          for (final key in sortedKeys.take(history.length - 90)) {
            history.remove(key);
          }
        }
        _box?.put(_keyGoalHistory, history);
        _updateStreak(history);
      }

      // Save last sensor reading as new baseline
      final lastSensor = _box?.get(_keyLastSensorSteps, defaultValue: 0) ?? 0;
      _box?.put(_keyBaseline, lastSensor);
      _box?.put(_keyTodaySteps, 0);
      _box?.put(_keyHourlySteps, <String, int>{});
      _box?.put(_keyTrackingDate, today);
    }
  }

  /// Calculate distance in meters from steps
  double distanceFromSteps(int steps) => steps * 0.762;

  /// Calculate calories from steps
  double caloriesFromSteps(int steps) => steps * 0.04;

  /// Get today's date string YYYY-MM-DD
  String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Restore goal history from server data (called after reinstall when Hive is empty)
  Future<void> restoreGoalHistoryFromServer(List<Map<String, dynamic>> serverRecords) async {
    if (_box == null || !_box!.isOpen) return;

    final history = goalHistory;
    for (final record in serverRecords) {
      final date = record['date'] as String? ?? '';
      final steps = record['steps'] as int? ?? 0;
      if (date.isEmpty) continue;

      // Don't overwrite today's local data (sensor is more accurate)
      if (date == _todayDateStr() && todaySteps > 0) continue;

      // Don't overwrite existing local records
      if (history.containsKey(date)) continue;

      final goal = dailyGoal;
      history[date] = {
        'steps': steps,
        'goal': goal,
        'achieved': steps >= goal,
      };
    }

    await _box?.put(_keyGoalHistory, history);
    _updateStreak(history);

    debugPrint('Restored ${serverRecords.length} records from server into goal history');
  }

  /// Get today's date for sync
  String get todayDate => _todayDateStr();

  /// Dispose resources
  Future<void> dispose() async {
    await stopTracking();
    await _stepController.close();
    await _statusController.close();
    await _box?.close();
  }
}
