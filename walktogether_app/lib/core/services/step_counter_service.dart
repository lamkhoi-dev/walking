import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for counting steps using device pedometer sensor.
/// Stores data locally in Hive for offline resilience.
class StepCounterService {
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  static const String _boxName = 'step_counter';
  static const String _keyBaseline = 'baseline_steps';
  static const String _keyLastSensorSteps = 'last_sensor_steps';
  static const String _keyTodaySteps = 'today_steps';
  static const String _keyTrackingDate = 'tracking_date';
  static const String _keyHourlySteps = 'hourly_steps';
  static const String _keyIsTracking = 'is_tracking';

  late final Pedometer _pedometer = Pedometer();
  Box? _box;
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

  /// Get hourly steps map (hour string → step count)
  Map<String, int> get hourlySteps {
    final raw = _box?.get(_keyHourlySteps);
    if (raw is Map) {
      return Map<String, int>.from(raw);
    }
    return {};
  }

  /// Initialize Hive box for step storage
  Future<void> init() async {
    if (_isInitialized) return;

    _box = await Hive.openBox(_boxName);

    // Check if date changed (midnight reset)
    _checkDateReset();

    // Restore tracking state
    _isTracking = _box?.get(_keyIsTracking, defaultValue: false) ?? false;
    _isInitialized = true;
  }

  /// Start step tracking
  Future<void> startTracking() async {
    if (!_isInitialized) await init();
    if (_isTracking) return;

    // Request ACTIVITY_RECOGNITION permission (required on Android 10+)
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        debugPrint('ACTIVITY_RECOGNITION permission denied: $status');
        throw Exception('Cần cấp quyền nhận diện hoạt động để đếm bước chân');
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

  /// Check if a new day has started → reset baseline
  void _checkDateReset() {
    final today = _todayDateStr();
    final storedDate = _box?.get(_keyTrackingDate, defaultValue: '') ?? '';

    if (storedDate != today) {
      debugPrint('New day detected: $storedDate → $today. Resetting steps.');
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
