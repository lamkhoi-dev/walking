import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/step_counter_service.dart';
import '../../../../core/services/step_sync_service.dart';
import '../../data/repositories/step_repository.dart';

// ===== EVENTS =====
abstract class StepTrackerEvent extends Equatable {
  const StepTrackerEvent();
  @override
  List<Object?> get props => [];
}

/// Start tracking steps via pedometer
class StepTrackerStartRequested extends StepTrackerEvent {}

/// Stop tracking steps
class StepTrackerStopRequested extends StepTrackerEvent {}

/// Reset tracker state (on logout)
class StepTrackerResetRequested extends StepTrackerEvent {}

/// Internal: steps updated from sensor
class _StepTrackerStepsUpdated extends StepTrackerEvent {
  final int steps;
  const _StepTrackerStepsUpdated(this.steps);
  @override
  List<Object?> get props => [steps];
}

/// Internal: pedestrian status changed
class _StepTrackerStatusUpdated extends StepTrackerEvent {
  final String status;
  const _StepTrackerStatusUpdated(this.status);
  @override
  List<Object?> get props => [status];
}

/// Internal: sync status changed
class _StepTrackerSyncStatusUpdated extends StepTrackerEvent {
  final StepSyncStatus syncStatus;
  const _StepTrackerSyncStatusUpdated(this.syncStatus);
  @override
  List<Object?> get props => [syncStatus];
}

/// Internal: data restored from server (triggers UI rebuild)
class _StepTrackerDataRestored extends StepTrackerEvent {}

/// Trigger a manual sync
class StepTrackerSyncRequested extends StepTrackerEvent {}

/// Change daily step goal
class StepTrackerGoalChanged extends StepTrackerEvent {
  final int newGoal;
  const StepTrackerGoalChanged(this.newGoal);
  @override
  List<Object?> get props => [newGoal];
}

// ===== STATES =====
abstract class StepTrackerState extends Equatable {
  const StepTrackerState();
  @override
  List<Object?> get props => [];
}

class StepTrackerInitial extends StepTrackerState {}

/// Loading state while syncing from server
class StepTrackerLoading extends StepTrackerState {}

class StepTrackerRunning extends StepTrackerState {
  final int todaySteps;
  final double distance; // meters
  final double calories;
  final int goalSteps;
  final double progress; // 0.0 → 1.0+
  final Map<String, int> hourlySteps;
  final String pedestrianStatus; // walking, stopped, unknown
  final StepSyncStatus syncStatus;
  final bool isTracking;

  const StepTrackerRunning({
    required this.todaySteps,
    required this.distance,
    required this.calories,
    required this.goalSteps,
    required this.progress,
    required this.hourlySteps,
    required this.pedestrianStatus,
    required this.syncStatus,
    required this.isTracking,
  });

  @override
  List<Object?> get props => [
        todaySteps,
        distance,
        calories,
        goalSteps,
        progress,
        hourlySteps,
        pedestrianStatus,
        syncStatus,
        isTracking,
      ];

  StepTrackerRunning copyWith({
    int? todaySteps,
    double? distance,
    double? calories,
    int? goalSteps,
    double? progress,
    Map<String, int>? hourlySteps,
    String? pedestrianStatus,
    StepSyncStatus? syncStatus,
    bool? isTracking,
  }) {
    return StepTrackerRunning(
      todaySteps: todaySteps ?? this.todaySteps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      goalSteps: goalSteps ?? this.goalSteps,
      progress: progress ?? this.progress,
      hourlySteps: hourlySteps ?? this.hourlySteps,
      pedestrianStatus: pedestrianStatus ?? this.pedestrianStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      isTracking: isTracking ?? this.isTracking,
    );
  }
}

class StepTrackerError extends StepTrackerState {
  final String message;
  const StepTrackerError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class StepTrackerBloc extends Bloc<StepTrackerEvent, StepTrackerState> {
  final StepCounterService _counterService;
  final StepSyncService _syncService;
  final StepRepository? _stepRepository;

  static const _notifChannel = MethodChannel('com.runly.app/notification');

  StreamSubscription<int>? _stepSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<StepSyncStatus>? _syncSub;

  StepTrackerBloc({
    StepCounterService? counterService,
    StepSyncService? syncService,
    StepRepository? stepRepository,
  })  : _counterService = counterService ?? StepCounterService(),
        _syncService = syncService ?? StepSyncService(),
        _stepRepository = stepRepository,
        super(StepTrackerInitial()) {
    on<StepTrackerStartRequested>(_onStart);
    on<StepTrackerStopRequested>(_onStop);
    on<StepTrackerResetRequested>(_onReset);
    on<_StepTrackerStepsUpdated>(_onStepsUpdated);
    on<_StepTrackerStatusUpdated>(_onStatusUpdated);
    on<_StepTrackerSyncStatusUpdated>(_onSyncStatusUpdated);
    on<StepTrackerSyncRequested>(_onSyncRequested);
    on<StepTrackerGoalChanged>(_onGoalChanged);
    on<_StepTrackerDataRestored>(_onDataRestored);
  }

  int get _goal => _counterService.dailyGoal;

  StepTrackerRunning _buildRunningState({
    required int steps,
    String? pedestrianStatus,
    StepSyncStatus? syncStatus,
    required bool isTracking,
  }) {
    final distance = _counterService.distanceFromSteps(steps);
    final calories = _counterService.caloriesFromSteps(steps);
    final progress = _goal > 0 ? steps / _goal : 0.0;

    return StepTrackerRunning(
      todaySteps: steps,
      distance: distance,
      calories: calories,
      goalSteps: _goal,
      progress: progress,
      hourlySteps: _counterService.hourlySteps,
      pedestrianStatus: pedestrianStatus ?? 'unknown',
      syncStatus: syncStatus ?? StepSyncStatus.idle,
      isTracking: isTracking,
    );
  }

  Future<void> _onStart(
    StepTrackerStartRequested event,
    Emitter<StepTrackerState> emit,
  ) async {
    // Guard: don't start if already tracking
    if (state is StepTrackerRunning &&
        (state as StepTrackerRunning).isTracking) {
      return;
    }

    try {
      // Show loading state while syncing from server
      emit(StepTrackerLoading());

      await _counterService.init();

      // Wait for user box to be ready (switchUser called from auth listener)
      int retries = 0;
      while (_counterService.currentUserId == null && retries < 30) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }

      if (_counterService.currentUserId == null) {
        debugPrint('Warning: switchUser not completed after ${retries * 200}ms, proceeding anyway');
      }

      // CRITICAL: Fetch today's steps from server BEFORE starting tracking
      // This prevents overwriting server data with lower local value
      if (_stepRepository != null) {
        try {
          final serverToday = await _stepRepository.getToday();
          await _counterService.syncFromServer(serverToday.steps);
          debugPrint('Server today steps: ${serverToday.steps}');
        } catch (e) {
          debugPrint('Failed to fetch today steps from server: $e (continuing with local)');
        }
      }

      // Android: foreground service owns pedometer (background-safe)
      // iOS: no foreground service, use local pedometer subscription
      final useAndroidForeground = Platform.isAndroid;

      if (useAndroidForeground) {
        // Start foreground service only if not already running
        final isServiceRunning = await FlutterForegroundTask.isRunningService;
        if (!isServiceRunning) {
          await _counterService.startForegroundService();
        } else {
          debugPrint('Foreground service already running — just re-registering callback');
        }

        await _counterService.startTracking(foregroundServiceActive: true);

        // Send current daily goal to TaskHandler for notification progress bar
        FlutterForegroundTask.sendDataToTask({
          'command': 'updateGoal',
          'goal': _counterService.dailyGoal,
        });

        // Register callback for receiving data from foreground service TaskHandler
        FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
      } else {
        // iOS: subscribe local pedometer directly
        await _counterService.startTracking(foregroundServiceActive: false);
        debugPrint('iOS: using local pedometer subscription (no foreground service)');
      }

      // Listen to step updates (for foreground tracking)
      _stepSub?.cancel();
      _stepSub = _counterService.stepStream.listen(
        (steps) => add(_StepTrackerStepsUpdated(steps)),
      );

      // Listen to pedestrian status
      _statusSub?.cancel();
      _statusSub = _counterService.statusStream.listen(
        (status) => add(_StepTrackerStatusUpdated(status)),
      );

      // Listen to sync status
      _syncSub?.cancel();
      _syncSub = _syncService.syncStatusStream.listen(
        (status) => add(_StepTrackerSyncStatusUpdated(status)),
      );

      // Start periodic sync
      _syncService.startPeriodicSync();

      // Restore goal history from server if local Hive is empty (e.g., after reinstall)
      if (_counterService.goalHistory.isEmpty && _stepRepository != null) {
        _restoreFromServer();
      }

      // Emit initial running state with current steps
      emit(_buildRunningState(
        steps: _counterService.todaySteps,
        isTracking: true,
      ));

      // Force emit current steps to trigger UI update
      add(_StepTrackerStepsUpdated(_counterService.todaySteps));
    } catch (e) {
      emit(StepTrackerError(e.toString()));
    }
  }

  /// Fetch step history from server and restore into local Hive (background, non-blocking)
  Future<void> _restoreFromServer() async {
    try {
      // Fetch all history (no date range limit)
      final records = await _stepRepository!.getHistory();

      if (records.isNotEmpty) {
        final serverData = records
            .map((r) => {'date': r.date, 'steps': r.steps})
            .toList();
        await _counterService.restoreGoalHistoryFromServer(serverData);

        // Also restore today's steps if local is 0 but server has data
        final todayRecord = records.where((r) => r.date == _counterService.todayDate).firstOrNull;
        if (todayRecord != null && _counterService.todaySteps == 0 && todayRecord.steps > 0) {
          debugPrint('Restored today steps from server: ${todayRecord.steps}');
        }

        // Trigger UI rebuild via event (emit can't be used outside event handlers)
        add(_StepTrackerDataRestored());
      }
    } catch (e) {
      debugPrint('Failed to restore step history from server: $e');
    }
  }

  Future<void> _onDataRestored(
    _StepTrackerDataRestored event,
    Emitter<StepTrackerState> emit,
  ) async {
    if (state is StepTrackerRunning) {
      emit(_buildRunningState(
        steps: _counterService.todaySteps,
        isTracking: _counterService.isTracking,
      ));
    }
  }

  Future<void> _onStop(
    StepTrackerStopRequested event,
    Emitter<StepTrackerState> emit,
  ) async {
    await _counterService.stopTracking();
    await _counterService.stopForegroundService();
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    _syncService.stopPeriodicSync();

    // Do a final sync before stopping
    await _syncService.syncNow();

    if (state is StepTrackerRunning) {
      final current = state as StepTrackerRunning;
      emit(current.copyWith(isTracking: false));
    }
  }

  /// Reset tracker to initial state (on logout)
  Future<void> _onReset(
    StepTrackerResetRequested event,
    Emitter<StepTrackerState> emit,
  ) async {
    // Cancel all subscriptions
    await _stepSub?.cancel();
    await _statusSub?.cancel();
    await _syncSub?.cancel();
    _stepSub = null;
    _statusSub = null;
    _syncSub = null;

    // Stop tracking and sync
    await _counterService.stopTracking();
    await _counterService.stopForegroundService();
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    _syncService.stopPeriodicSync();

    // Detach user — closes Hive box safely AFTER all tracking is stopped
    await _counterService.detachUser();
    _syncService.clearQueue();

    // Reset to initial state so next start will work
    emit(StepTrackerInitial());
    debugPrint('StepTrackerBloc reset to initial state');
  }

  void _onStepsUpdated(
    _StepTrackerStepsUpdated event,
    Emitter<StepTrackerState> emit,
  ) {
    final current = state;
    final pedestrianStatus =
        current is StepTrackerRunning ? current.pedestrianStatus : 'unknown';
    final syncStatus =
        current is StepTrackerRunning ? current.syncStatus : StepSyncStatus.idle;
    final isTracking =
        current is StepTrackerRunning ? current.isTracking : true;

    emit(_buildRunningState(
      steps: event.steps,
      pedestrianStatus: pedestrianStatus,
      syncStatus: syncStatus,
      isTracking: isTracking,
    ));

    // Smart sync: check if steps changed significantly
    _syncService.checkAndSync();
  }

  void _onStatusUpdated(
    _StepTrackerStatusUpdated event,
    Emitter<StepTrackerState> emit,
  ) {
    if (state is StepTrackerRunning) {
      emit((state as StepTrackerRunning).copyWith(
        pedestrianStatus: event.status,
      ));
    }
  }

  void _onSyncStatusUpdated(
    _StepTrackerSyncStatusUpdated event,
    Emitter<StepTrackerState> emit,
  ) {
    if (state is StepTrackerRunning) {
      emit((state as StepTrackerRunning).copyWith(
        syncStatus: event.syncStatus,
      ));
    }
  }

  Future<void> _onSyncRequested(
    StepTrackerSyncRequested event,
    Emitter<StepTrackerState> emit,
  ) async {
    await _syncService.syncNow();
  }

  Future<void> _onGoalChanged(
    StepTrackerGoalChanged event,
    Emitter<StepTrackerState> emit,
  ) async {
    await _counterService.setDailyGoal(event.newGoal);
    if (state is StepTrackerRunning) {
      final current = state as StepTrackerRunning;
      final progress = event.newGoal > 0 ? current.todaySteps / event.newGoal : 0.0;
      emit(current.copyWith(
        goalSteps: event.newGoal,
        progress: progress,
      ));
    }
  }

  /// Callback for data from foreground service TaskHandler
  void _onForegroundTaskData(Object data) {
    if (data is Map) {
      final steps = data['steps'] as int? ?? 0;
      final status = data['status'] as String? ?? 'unknown';
      if (steps > 0) {
        add(_StepTrackerStepsUpdated(steps));
        _updateNativeNotification(steps, status);
      }
      if (status != 'unknown') {
        add(_StepTrackerStatusUpdated(status));
      }
    }
  }

  /// Call native Android to show custom RemoteViews notification with real icons
  void _updateNativeNotification(int steps, String status) {
    final goal = _counterService.dailyGoal;
    final pct = goal > 0 ? (steps / goal * 100).clamp(0, 100).toInt() : 0;
    final km = (steps * 0.762 / 1000).toStringAsFixed(1);
    final cal = (steps * 0.04).toStringAsFixed(0);
    final min = (steps * 0.01).toStringAsFixed(0);

    String motivation;
    if (pct >= 100) {
      motivation = 'M\u1ee5c ti\u00eau ho\u00e0n th\u00e0nh!';
    } else if (pct >= 75) {
      motivation = 'S\u1eafp \u0111\u1ea1t r\u1ed3i, c\u1ed1 l\u00ean!';
    } else if (pct >= 50) {
      motivation = 'H\u01a1n n\u1eeda \u0111\u01b0\u1eddng r\u1ed3i!';
    } else if (pct >= 25) {
      motivation = '\u0110ang ti\u1ebfn b\u1ed9, c\u1ed1 l\u00ean!';
    } else if (steps > 0) {
      motivation = '\u0110ang \u0111\u1ebfm b\u01b0\u1edbc...';
    } else {
      motivation = 'S\u1eb5n s\u00e0ng \u0111\u1ebfm b\u01b0\u1edbc';
    }

    try {
      _notifChannel.invokeMethod('showStepNotification', {
        'steps': steps,
        'goal': goal,
        'distanceKm': km,
        'calories': cal,
        'minutes': min,
        'progress': pct,
        'motivation': motivation,
        'isWalking': status == 'walking',
      });
    } catch (e) {
      // Silently fail — TaskHandler's fallback notification still shows
      debugPrint('Native notification failed: $e');
    }
  }

  @override
  Future<void> close() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _syncSub?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    return super.close();
  }
}
