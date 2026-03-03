import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/contest_model.dart';
import '../../data/repositories/contest_repository.dart';

// ===== EVENTS =====
abstract class ContestDetailEvent extends Equatable {
  const ContestDetailEvent();
  @override
  List<Object?> get props => [];
}

class ContestDetailLoadRequested extends ContestDetailEvent {
  final String contestId;
  const ContestDetailLoadRequested(this.contestId);
  @override
  List<Object?> get props => [contestId];
}

class ContestDetailCancelRequested extends ContestDetailEvent {
  final String contestId;
  const ContestDetailCancelRequested(this.contestId);
  @override
  List<Object?> get props => [contestId];
}

// ===== STATES =====
abstract class ContestDetailState extends Equatable {
  const ContestDetailState();
  @override
  List<Object?> get props => [];
}

class ContestDetailInitial extends ContestDetailState {}

class ContestDetailLoading extends ContestDetailState {}

class ContestDetailLoaded extends ContestDetailState {
  final ContestModel contest;
  const ContestDetailLoaded(this.contest);
  @override
  List<Object?> get props => [contest];
}

class ContestDetailCancelled extends ContestDetailState {}

class ContestDetailError extends ContestDetailState {
  final String message;
  const ContestDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class ContestDetailBloc
    extends Bloc<ContestDetailEvent, ContestDetailState> {
  final ContestRepository _repository;

  ContestDetailBloc({required ContestRepository repository})
      : _repository = repository,
        super(ContestDetailInitial()) {
    on<ContestDetailLoadRequested>(_onLoad);
    on<ContestDetailCancelRequested>(_onCancel);
  }

  Future<void> _onLoad(
    ContestDetailLoadRequested event,
    Emitter<ContestDetailState> emit,
  ) async {
    emit(ContestDetailLoading());
    try {
      final contest = await _repository.getContestById(event.contestId);
      emit(ContestDetailLoaded(contest));
    } catch (e) {
      emit(ContestDetailError(e.toString()));
    }
  }

  Future<void> _onCancel(
    ContestDetailCancelRequested event,
    Emitter<ContestDetailState> emit,
  ) async {
    try {
      await _repository.cancelContest(event.contestId);
      emit(ContestDetailCancelled());
    } catch (e) {
      emit(ContestDetailError(e.toString()));
    }
  }
}
