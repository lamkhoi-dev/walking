import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/step_counter_service.dart';
import '../../../../core/services/step_sync_service.dart';

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

  StreamSubscription<int>? _stepSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<StepSyncStatus>? _syncSub;

  StepTrackerBloc({
    StepCounterService? counterService,
    StepSyncService? syncService,
  })  : _counterService = counterService ?? StepCounterService(),
        _syncService = syncService ?? StepSyncService(),
        super(StepTrackerInitial()) {
    on<StepTrackerStartRequested>(_onStart);
    on<StepTrackerStopRequested>(_onStop);
    on<_StepTrackerStepsUpdated>(_onStepsUpdated);
    on<_StepTrackerStatusUpdated>(_onStatusUpdated);
    on<_StepTrackerSyncStatusUpdated>(_onSyncStatusUpdated);
    on<StepTrackerSyncRequested>(_onSyncRequested);
    on<StepTrackerGoalChanged>(_onGoalChanged);
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
    // Guard: don't start if already running
    if (state is StepTrackerRunning) return;

    try {
      await _counterService.init();

      // Wait for user box to be ready (switchUser called from auth listener)
      int retries = 0;
      while (_counterService.currentUserId == null && retries < 20) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }

      await _counterService.startTracking();

      // Listen to step updates
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

      // Emit initial running state with current steps
      emit(_buildRunningState(
        steps: _counterService.todaySteps,
        isTracking: true,
      ));
    } catch (e) {
      emit(StepTrackerError(e.toString()));
    }
  }

  Future<void> _onStop(
    StepTrackerStopRequested event,
    Emitter<StepTrackerState> emit,
  ) async {
    await _counterService.stopTracking();
    _syncService.stopPeriodicSync();

    // Do a final sync before stopping
    await _syncService.syncNow();

    if (state is StepTrackerRunning) {
      final current = state as StepTrackerRunning;
      emit(current.copyWith(isTracking: false));
    }
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

  @override
  Future<void> close() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _syncSub?.cancel();
    return super.close();
  }
}
