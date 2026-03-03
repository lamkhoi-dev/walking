import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/contest_model.dart';
import '../../data/repositories/contest_repository.dart';

// ===== EVENTS =====
abstract class ContestListEvent extends Equatable {
  const ContestListEvent();
  @override
  List<Object?> get props => [];
}

class ContestListLoadRequested extends ContestListEvent {
  final String? groupId;
  const ContestListLoadRequested({this.groupId});
  @override
  List<Object?> get props => [groupId];
}

class ContestListRefreshRequested extends ContestListEvent {
  final String? groupId;
  const ContestListRefreshRequested({this.groupId});
  @override
  List<Object?> get props => [groupId];
}

// ===== STATES =====
abstract class ContestListState extends Equatable {
  const ContestListState();
  @override
  List<Object?> get props => [];
}

class ContestListInitial extends ContestListState {}

class ContestListLoading extends ContestListState {}

class ContestListLoaded extends ContestListState {
  final List<ContestModel> contests;
  final ContestModel? activeContest;
  final List<ContestModel> upcomingContests;
  final List<ContestModel> pastContests;

  const ContestListLoaded({
    required this.contests,
    this.activeContest,
    this.upcomingContests = const [],
    this.pastContests = const [],
  });

  @override
  List<Object?> get props =>
      [contests, activeContest, upcomingContests, pastContests];
}

class ContestListError extends ContestListState {
  final String message;
  const ContestListError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class ContestListBloc extends Bloc<ContestListEvent, ContestListState> {
  final ContestRepository _repository;

  ContestListBloc({required ContestRepository repository})
      : _repository = repository,
        super(ContestListInitial()) {
    on<ContestListLoadRequested>(_onLoad);
    on<ContestListRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    ContestListLoadRequested event,
    Emitter<ContestListState> emit,
  ) async {
    emit(ContestListLoading());
    await _loadContests(event.groupId, emit);
  }

  Future<void> _onRefresh(
    ContestListRefreshRequested event,
    Emitter<ContestListState> emit,
  ) async {
    await _loadContests(event.groupId, emit);
  }

  Future<void> _loadContests(
    String? groupId,
    Emitter<ContestListState> emit,
  ) async {
    try {
      final contests = await _repository.getContests(groupId: groupId);

      // Categorize contests
      ContestModel? activeContest;
      final upcomingContests = <ContestModel>[];
      final pastContests = <ContestModel>[];

      for (final contest in contests) {
        switch (contest.status) {
          case 'active':
            activeContest ??= contest;
            break;
          case 'upcoming':
            upcomingContests.add(contest);
            break;
          case 'completed':
          case 'cancelled':
            pastContests.add(contest);
            break;
        }
      }

      emit(ContestListLoaded(
        contests: contests,
        activeContest: activeContest,
        upcomingContests: upcomingContests,
        pastContests: pastContests,
      ));
    } catch (e) {
      emit(ContestListError(e.toString()));
    }
  }
}
