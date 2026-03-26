import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'step_counter_task.dart';

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
  static const String _keyServerOffset = 'server_offset'; // Steps from server at last sync

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
  int get todaySteps => (_box != null && _box!.isOpen) ? (_box?.get(_keyTodaySteps, defaultValue: 0) ?? 0) : 0;
  int get serverOffset => (_box != null && _box!.isOpen) ? ((_box?.get(_keyServerOffset, defaultValue: 0) ?? 0) as int) : 0;
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

  /// Initialize Hive box + foreground task config
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _initForegroundTask();
  }

  /// Configure foreground task notification & options
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'step_counter_channel',
        channelName: 'Đếm bước chân',
        channelDescription: 'Hiển thị khi đang đếm bước chân.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        showWhen: false,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Start foreground service for background step counting
  Future<void> startForegroundService() async {
    if (_currentUserId == null) return;

    // Save userId so TaskHandler can find the Hive box
    final metaBox = await Hive.openBox('foreground_meta');
    await metaBox.put('userId', _currentUserId!);
    await metaBox.close();

    // Request notification permission (Android 13+)
    if (Platform.isAndroid) {
      final notifStatus = await Permission.notification.request();
      debugPrint('Notification permission: $notifStatus');
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 200, // Must match StepNotificationHelper.NOTIFICATION_ID
      notificationTitle: 'Đang đếm bước chân...',
      notificationText: 'Đang khởi động...',
      callback: stepCounterCallback,
    );
    debugPrint('Foreground service start: $result');
  }

  /// Stop foreground service
  Future<void> stopForegroundService() async {
    final result = await FlutterForegroundTask.stopService();
    debugPrint('Foreground service stop: $result');
  }

  /// Switch to a user-specific Hive box. Call on login.
  Future<void> switchUser(String userId) async {
    // If same user and box already open, just ensure tracking state is reset
    if (_currentUserId == userId && _box != null && _box!.isOpen) {
      _isTracking = false;
      debugPrint('Step counter: same user, reset tracking state');
      return;
    }

    // Stop tracking & close previous box safely
    await stopTracking();
    if (_box != null) {
      try {
        if (_box!.isOpen) await _box!.close();
      } catch (e) {
        debugPrint('Warning: error closing previous box: $e');
      }
      _box = null;
    }

    _currentUserId = userId;
    final boxName = '$_boxPrefix$userId';
    _box = await Hive.openBox(boxName);

    // Check if date changed (midnight reset)
    _checkDateReset();

    // Reset tracking state — actual tracking is restarted by the bloc
    _isTracking = false;
    await _box?.put(_keyIsTracking, false);

    // Don't emit todaySteps here — bloc will emit correct value after syncFromServer

    debugPrint('Step counter switched to user: $userId (box: $boxName)');
  }

  /// Detach from current user (on logout). Stops tracking, closes box, but preserves data.
  Future<void> detachUser() async {
    await stopTracking();
    await stopForegroundService();
    _saveGoalRecord();
    if (_box != null) {
      try {
        if (_box!.isOpen) await _box!.close();
      } catch (e) {
        debugPrint('Warning: error closing box on detach: $e');
      }
      _box = null;
    }
    _currentUserId = null;
    _isTracking = false;
    _stepController.add(0);
    debugPrint('Step counter detached from user');
  }

  /// Start step tracking.
  /// If foreground service is handling pedometer, skip local subscription
  /// to avoid double-counting.
  Future<void> startTracking({bool foregroundServiceActive = false}) async {
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

    // If foreground service is active, it owns the pedometer subscription.
    // We only listen to data from the service via addTaskDataCallback.
    if (foregroundServiceActive) {
      debugPrint('Step tracking started (foreground service owns pedometer)');
      return;
    }

    // Cancel any existing subscriptions before creating new ones
    await _stepSubscription?.cancel();
    await _statusSubscription?.cancel();

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

    debugPrint('Step tracking started (local pedometer)');
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

  /// Set today's steps from server data (called on app start to prevent data loss)
  /// Uses MAX(localSteps, serverSteps) to preserve background-counted steps.
  Future<void> syncFromServer(int serverSteps) async {
    if (_box == null || !_box!.isOpen) return;

    final localSteps = todaySteps;

    if (localSteps >= serverSteps) {
      // Local (background) has MORE or EQUAL steps → keep local, don't reset
      debugPrint('syncFromServer: keeping local=$localSteps (server=$serverSteps)');
      _stepController.add(localSteps);
      return;
    }

    // Server has MORE steps (e.g., synced from another device) → update local
    await _box?.put(_keyServerOffset, serverSteps);
    await _box?.put(_keyBaseline, 0);
    await _box?.put(_keyLastSensorSteps, 0);
    await _box?.put(_keyTodaySteps, serverSteps);

    _stepController.add(serverSteps);
    debugPrint('syncFromServer: using server=$serverSteps (local=$localSteps was lower)');
  }

  /// Handle incoming step count from sensor
  void _onStepCount(int sensorSteps) {
    if (_box == null || !_box!.isOpen) return;

    // Check date reset first
    _checkDateReset();

    final baseline = (_box?.get(_keyBaseline, defaultValue: 0) ?? 0) as int;
    final lastSensor = (_box?.get(_keyLastSensorSteps, defaultValue: 0) ?? 0) as int;
    final offset = serverOffset; // Steps from server at last sync

    // Detect device reboot: sensor steps < last known sensor steps
    if (sensorSteps < lastSensor && lastSensor > 0) {
      // Device rebooted — set new baseline, preserve server offset
      debugPrint('Device reboot detected. Resetting baseline.');
      final localSteps = todaySteps - offset; // Local steps only (exclude server offset)
      _box?.put(_keyBaseline, sensorSteps - localSteps);
      _box?.put(_keyLastSensorSteps, sensorSteps);
      return;
    }

    // First reading after sync — set baseline (local steps start from 0)
    if (baseline == 0 && lastSensor == 0) {
      _box?.put(_keyBaseline, sensorSteps);
      _box?.put(_keyLastSensorSteps, sensorSteps);
      debugPrint('First sensor reading: baseline=$sensorSteps, serverOffset=$offset');
      // Don't change todaySteps here - keep serverOffset value
      return;
    }

    // Calculate today's steps = serverOffset + localSteps
    final localSteps = sensorSteps - baseline;
    final clampedLocalSteps = localSteps < 0 ? 0 : localSteps;
    final totalSteps = offset + clampedLocalSteps;

    _box?.put(_keyTodaySteps, totalSteps);
    _box?.put(_keyLastSensorSteps, sensorSteps);

    // Update hourly breakdown
    _updateHourlySteps(totalSteps);

    // Emit to listeners
    _stepController.add(totalSteps);
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
        _box?.put(_keyGoalHistory, history);
        _updateStreak(history);
      }

      // Reset all counters for new day
      final lastSensor = _box?.get(_keyLastSensorSteps, defaultValue: 0) ?? 0;
      _box?.put(_keyBaseline, lastSensor);
      _box?.put(_keyTodaySteps, 0);
      _box?.put(_keyServerOffset, 0); // Reset server offset for new day
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
