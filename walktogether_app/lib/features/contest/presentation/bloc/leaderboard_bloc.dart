import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/leaderboard_entry_model.dart';
import '../../data/repositories/contest_repository.dart';
import '../../../../core/socket/socket_service.dart';

// ===== EVENTS =====
abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();
  @override
  List<Object?> get props => [];
}

class LeaderboardLoadRequested extends LeaderboardEvent {
  final String contestId;
  final String? filterDate;
  const LeaderboardLoadRequested(this.contestId, {this.filterDate});
  @override
  List<Object?> get props => [contestId, filterDate];
}

class LeaderboardRefreshRequested extends LeaderboardEvent {
  const LeaderboardRefreshRequested();
}

class LeaderboardDateFilterChanged extends LeaderboardEvent {
  final String? filterDate;
  const LeaderboardDateFilterChanged(this.filterDate);
  @override
  List<Object?> get props => [filterDate];
}

class LeaderboardUpdated extends LeaderboardEvent {
  final List<LeaderboardEntryModel> entries;
  const LeaderboardUpdated(this.entries);
  @override
  List<Object?> get props => [entries];
}

// ===== STATES =====
abstract class LeaderboardState extends Equatable {
  const LeaderboardState();
  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoading extends LeaderboardState {}

class LeaderboardLoaded extends LeaderboardState {
  final String contestId;
  final List<LeaderboardEntryModel> entries;
  final String? filterDate;

  const LeaderboardLoaded({
    required this.contestId,
    required this.entries,
    this.filterDate,
  });

  /// Top 3 entries for podium
  List<LeaderboardEntryModel> get podium =>
      entries.where((e) => e.rank <= 3).toList();

  /// Entries ranked 4+
  List<LeaderboardEntryModel> get rest =>
      entries.where((e) => e.rank > 3).toList();

  @override
  List<Object?> get props => [contestId, entries, filterDate];
}

class LeaderboardError extends LeaderboardState {
  final String message;
  const LeaderboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final ContestRepository _repository;
  final SocketService _socketService;
  String? _currentContestId;
  String? _currentFilterDate;
  void Function(dynamic)? _onLeaderboardUpdateCallback;

  LeaderboardBloc({
    required ContestRepository repository,
    SocketService? socketService,
  })  : _repository = repository,
        _socketService = socketService ?? SocketService(),
        super(LeaderboardInitial()) {
    on<LeaderboardLoadRequested>(_onLoad);
    on<LeaderboardRefreshRequested>(_onRefresh);
    on<LeaderboardDateFilterChanged>(_onDateFilterChanged);
    on<LeaderboardUpdated>(_onUpdated);
  }

  void _setupSocketListener() {
    _onLeaderboardUpdateCallback = (data) {
      if (data is Map<String, dynamic>) {
        final contestId = data['contestId'] as String?;
        if (contestId == _currentContestId && data['leaderboard'] is List) {
          final entries = (data['leaderboard'] as List)
              .map((e) => LeaderboardEntryModel.fromJson(
                  e as Map<String, dynamic>))
              .toList();
          add(LeaderboardUpdated(entries));
        }
      }
    };
    _socketService.on('leaderboard:update', _onLeaderboardUpdateCallback!);
  }

  void _removeSocketListener() {
    if (_onLeaderboardUpdateCallback != null) {
      _socketService.off('leaderboard:update', _onLeaderboardUpdateCallback!);
      _onLeaderboardUpdateCallback = null;
    }
  }

  Future<void> _onLoad(
    LeaderboardLoadRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    // Unsubscribe from previous
    if (_currentContestId != null) {
      _socketService.emit('leaderboard:unsubscribe', {
        'contestId': _currentContestId,
      });
      _removeSocketListener();
    }

    _currentContestId = event.contestId;
    _currentFilterDate = event.filterDate;
    emit(LeaderboardLoading());

    try {
      final entries = await _repository.getLeaderboard(
        event.contestId,
        filterDate: event.filterDate,
      );

      // Subscribe to realtime updates
      _socketService.emit('leaderboard:subscribe', {
        'contestId': event.contestId,
      });
      _setupSocketListener();

      emit(LeaderboardLoaded(
        contestId: event.contestId,
        entries: entries,
        filterDate: event.filterDate,
      ));
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    LeaderboardRefreshRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    if (_currentContestId == null) return;

    try {
      final entries = await _repository.getLeaderboard(
        _currentContestId!,
        filterDate: _currentFilterDate,
      );
      emit(LeaderboardLoaded(
        contestId: _currentContestId!,
        entries: entries,
        filterDate: _currentFilterDate,
      ));
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }

  Future<void> _onDateFilterChanged(
    LeaderboardDateFilterChanged event,
    Emitter<LeaderboardState> emit,
  ) async {
    if (_currentContestId == null) return;
    
    _currentFilterDate = event.filterDate;
    emit(LeaderboardLoading());

    try {
      final entries = await _repository.getLeaderboard(
        _currentContestId!,
        filterDate: event.filterDate,
      );
      emit(LeaderboardLoaded(
        contestId: _currentContestId!,
        entries: entries,
        filterDate: event.filterDate,
      ));
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }

  Future<void> _onUpdated(
    LeaderboardUpdated event,
    Emitter<LeaderboardState> emit,
  ) async {
    if (_currentContestId != null) {
      emit(LeaderboardLoaded(
        contestId: _currentContestId!,
        entries: event.entries,
        filterDate: _currentFilterDate,
      ));
    }
  }

  @override
  Future<void> close() {
    if (_currentContestId != null) {
      _socketService.emit('leaderboard:unsubscribe', {
        'contestId': _currentContestId,
      });
    }
    _removeSocketListener();
    return super.close();
  }
}
