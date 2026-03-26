import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Top-level callback — MUST be top-level or static
@pragma('vm:entry-point')
void stepCounterCallback() {
  FlutterForegroundTask.setTaskHandler(StepCounterTaskHandler());
}

/// Runs pedometer in a foreground service isolate.
/// Persists steps to Hive so the main isolate can read them.
/// Uses flutter_local_notifications for a native progress bar.
class StepCounterTaskHandler extends TaskHandler {
  static const String _boxPrefix = 'step_counter_';
  static const String _keyBaseline = 'baseline_steps';
  static const String _keyLastSensorSteps = 'last_sensor_steps';
  static const String _keyTodaySteps = 'today_steps';
  static const String _keyTrackingDate = 'tracking_date';
  static const String _keyHourlySteps = 'hourly_steps';
  static const String _keyServerOffset = 'server_offset';
  static const String _keyDailyGoal = 'daily_goal';


  late final Pedometer _pedometer;
  StreamSubscription<int>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  Box? _box;
  String _currentStatus = 'unknown';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[FG Task] Started at $timestamp by ${starter.name}');

    _pedometer = Pedometer();

    // Init Hive in service isolate
    await Hive.initFlutter();

    // Read userId from shared prefs via Hive
    final metaBox = await Hive.openBox('foreground_meta');
    final userId = metaBox.get('userId') as String?;
    await metaBox.close();

    if (userId == null) {
      debugPrint('[FG Task] No userId found, cannot track');
      return;
    }

    // Open user-specific box (service isolate has exclusive access)
    final boxName = '$_boxPrefix$userId';
    try {
      _box = await Hive.openBox(boxName);
    } catch (e) {
      debugPrint('[FG Task] Failed to open box $boxName: $e');
      return;
    }

    // Subscribe to pedometer
    _stepSub = _pedometer.stepCountStream().listen(
      _onSensorStep,
      onError: (e) => debugPrint('[FG Task] Step error: $e'),
      cancelOnError: false,
    );

    _statusSub = _pedometer.pedestrianStatusStream().listen(
      (status) {
        _currentStatus = status.name;
      },
      onError: (e) => debugPrint('[FG Task] Status error: $e'),
      cancelOnError: false,
    );

    debugPrint('[FG Task] Pedometer subscribed for user: $userId');
  }

  void _onSensorStep(int sensorSteps) {
    if (_box == null || !_box!.isOpen) return;

    _checkDateReset();

    final baseline = (_box!.get(_keyBaseline, defaultValue: 0) ?? 0) as int;
    final lastSensor = (_box!.get(_keyLastSensorSteps, defaultValue: 0) ?? 0) as int;
    final offset = (_box!.get(_keyServerOffset, defaultValue: 0) ?? 0) as int;

    // Detect device reboot: sensor steps < last known
    if (sensorSteps < lastSensor && lastSensor > 0) {
      final currentTotal = (_box!.get(_keyTodaySteps, defaultValue: 0) ?? 0) as int;
      final localSteps = currentTotal - offset;
      final safeLocalSteps = localSteps < 0 ? 0 : localSteps;
      _box!.put(_keyBaseline, sensorSteps - safeLocalSteps);
      _box!.put(_keyLastSensorSteps, sensorSteps);
      debugPrint('[FG Task] Reboot: new baseline=${sensorSteps - safeLocalSteps}');
      return;
    }

    // First reading — set baseline
    if (baseline == 0 && lastSensor == 0) {
      _box!.put(_keyBaseline, sensorSteps);
      _box!.put(_keyLastSensorSteps, sensorSteps);
      debugPrint('[FG Task] First reading: baseline=$sensorSteps');
      return;
    }

    // Calculate total = offset + (sensor - baseline)
    final localSteps = sensorSteps - baseline;
    final clamped = localSteps < 0 ? 0 : localSteps;
    final totalSteps = offset + clamped;

    _box!.put(_keyTodaySteps, totalSteps);
    _box!.put(_keyLastSensorSteps, sensorSteps);
    _updateHourlySteps(totalSteps);

    // Send to main isolate
    FlutterForegroundTask.sendDataToMain({
      'steps': totalSteps,
      'status': _currentStatus,
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_box == null || !_box!.isOpen) return;

    final steps = (_box!.get(_keyTodaySteps, defaultValue: 0) ?? 0) as int;

    // Send data to main isolate — the premium notification is handled by
    // StepTrackerBloc → native Kotlin (NOTIFICATION_ID=200)
    FlutterForegroundTask.sendDataToMain({
      'steps': steps,
      'status': _currentStatus,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[FG Task] Destroyed at $timestamp');
    await _stepSub?.cancel();
    await _statusSub?.cancel();
    await _box?.close();
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final command = data['command'];
      if (command == 'syncFromServer') {
        final serverSteps = data['steps'] as int? ?? 0;
        if (_box != null && _box!.isOpen) {
          final localSteps = (_box!.get(_keyTodaySteps, defaultValue: 0) ?? 0) as int;
          // Use MAX(local, server) — never overwrite higher background count
          if (serverSteps > localSteps) {
            _box!.put(_keyServerOffset, serverSteps);
            _box!.put(_keyBaseline, 0);
            _box!.put(_keyLastSensorSteps, 0);
            _box!.put(_keyTodaySteps, serverSteps);
            debugPrint('[FG Task] syncFromServer: server=$serverSteps > local=$localSteps, updated');
          } else {
            debugPrint('[FG Task] syncFromServer: keeping local=$localSteps (server=$serverSteps)');
          }
        }
      } else if (command == 'updateGoal') {
        final goal = data['goal'] as int? ?? 10000;
        _box?.put(_keyDailyGoal, goal);
      }
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/home');
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationDismissed() {}

  void _checkDateReset() {
    final today = _todayStr();
    final stored = (_box?.get(_keyTrackingDate, defaultValue: '') ?? '') as String;

    if (stored != today) {
      debugPrint('[FG Task] Date reset: $stored → $today');
      final lastSensor = _box?.get(_keyLastSensorSteps, defaultValue: 0) ?? 0;
      _box?.put(_keyBaseline, lastSensor);
      _box?.put(_keyTodaySteps, 0);
      _box?.put(_keyServerOffset, 0);
      _box?.put(_keyHourlySteps, <String, int>{});
      _box?.put(_keyTrackingDate, today);
    }
  }

  void _updateHourlySteps(int totalSteps) {
    final hour = DateTime.now().hour.toString().padLeft(2, '0');
    final raw = _box?.get(_keyHourlySteps);
    final hourly = raw is Map ? Map<String, int>.from(raw) : <String, int>{};
    hourly[hour] = totalSteps;
    _box?.put(_keyHourlySteps, hourly);
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
