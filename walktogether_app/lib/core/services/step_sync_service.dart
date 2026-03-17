import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../network/dio_client.dart';
import '../socket/socket_service.dart';
import 'step_counter_service.dart';

/// Sync service that periodically sends step data to the server.
/// Uses socket when available, falls back to REST API.
/// Maintains an offline queue for retries.
class StepSyncService {
  static final StepSyncService _instance = StepSyncService._internal();
  factory StepSyncService() => _instance;
  StepSyncService._internal();

  static const String _queueBoxName = 'step_sync_queue';

  DioClient? _dioClient;
  Box? _queueBox;
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isInitialized = false;

  final _syncStatusController = StreamController<StepSyncStatus>.broadcast();
  Stream<StepSyncStatus> get syncStatusStream => _syncStatusController.stream;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;
  int _lastSyncedSteps = 0;

  /// Initialize sync service with DioClient
  Future<void> init(DioClient dioClient) async {
    if (_isInitialized) return;

    _dioClient = dioClient;
    _queueBox = await Hive.openBox(_queueBoxName);
    _isInitialized = true;
  }

  /// Start periodic sync timer
  void startPeriodicSync() {
    stopPeriodicSync();
    _syncTimer = Timer.periodic(
      Duration(seconds: AppConstants.stepSyncInterval),
      (_) => syncNow(),
    );
    debugPrint('Step sync timer started (every ${AppConstants.stepSyncInterval}s)');
  }

  /// Stop periodic sync timer
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Check if steps changed significantly and sync if needed
  /// Call this from step counter when steps update
  void checkAndSync() {
    final stepService = StepCounterService();
    final currentSteps = stepService.todaySteps;
    final threshold = AppConstants.stepSyncThreshold;
    
    if (currentSteps - _lastSyncedSteps >= threshold) {
      syncNow();
    }
  }

  /// Sync steps now (called by timer or manually)
  Future<bool> syncNow() async {
    if (_isSyncing || !_isInitialized) return false;
    _isSyncing = true;
    _syncStatusController.add(StepSyncStatus.syncing);

    try {
      final stepService = StepCounterService();
      final steps = stepService.todaySteps;
      final date = stepService.todayDate;
      final hourlySteps = stepService.hourlySteps;

      // Skip if no steps recorded
      if (steps == 0) {
        _isSyncing = false;
        _syncStatusController.add(StepSyncStatus.idle);
        return true;
      }

      final data = {
        'date': date,
        'steps': steps,
        'hourlySteps': hourlySteps,
      };

      // Try socket first (faster)
      final socketService = SocketService();
      if (socketService.isConnected) {
        socketService.emit('steps:sync', data);
        _lastSyncTime = DateTime.now();
        _lastSyncedSteps = steps;
        _syncStatusController.add(StepSyncStatus.synced);
        _isSyncing = false;

        // Also flush any queued records
        await _flushQueue();
        return true;
      }

      // Fallback to REST
      if (_dioClient != null) {
        try {
          await _dioClient!.post(
            ApiEndpoints.stepSync,
            data: data,
          );
          _lastSyncTime = DateTime.now();
          _lastSyncedSteps = steps;
          _syncStatusController.add(StepSyncStatus.synced);
          _isSyncing = false;

          // Flush queue
          await _flushQueue();
          return true;
        } catch (e) {
          debugPrint('REST sync failed: $e');
        }
      }

      // Offline — queue for later
      await _addToQueue(data);
      _syncStatusController.add(StepSyncStatus.offline);
      _isSyncing = false;
      return false;
    } catch (e) {
      debugPrint('Sync error: $e');
      _syncStatusController.add(StepSyncStatus.error);
      _isSyncing = false;
      return false;
    }
  }

  /// Add a step record to the offline queue
  Future<void> _addToQueue(Map<String, dynamic> data) async {
    if (_queueBox == null) return;

    // Use date as key (only keep latest per day)
    await _queueBox!.put(data['date'], data);
    debugPrint('Step record queued for sync: ${data['date']}');
  }

  /// Flush offline queue — send all pending records
  Future<void> _flushQueue() async {
    if (_queueBox == null || _queueBox!.isEmpty) return;

    final keys = _queueBox!.keys.toList();
    for (final key in keys) {
      final data = _queueBox!.get(key);
      if (data == null) continue;

      try {
        final socketService = SocketService();
        if (socketService.isConnected) {
          socketService.emit('steps:sync', Map<String, dynamic>.from(data));
        } else if (_dioClient != null) {
          await _dioClient!.post(
            ApiEndpoints.stepSync,
            data: Map<String, dynamic>.from(data),
          );
        }
        await _queueBox!.delete(key);
        debugPrint('Flushed queued record: $key');
      } catch (e) {
        debugPrint('Failed to flush queued record $key: $e');
        break; // Stop flushing on error — retry next time
      }
    }
  }

  /// Get pending sync count
  int get pendingCount => _queueBox?.length ?? 0;

  /// Clear sync queue (called on logout)
  Future<void> clearQueue() async {
    stopPeriodicSync();
    await _queueBox?.clear();
    _lastSyncTime = null;
    _syncStatusController.add(StepSyncStatus.idle);
    debugPrint('Step sync queue cleared');
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopPeriodicSync();
    await _syncStatusController.close();
    await _queueBox?.close();
  }
}

/// Sync status enum
enum StepSyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}
