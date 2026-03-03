import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository.dart';

// ===== EVENTS =====
abstract class GroupSearchEvent extends Equatable {
  const GroupSearchEvent();
  @override
  List<Object?> get props => [];
}

class GroupSearchQueryChanged extends GroupSearchEvent {
  final String query;
  const GroupSearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class GroupSearchCleared extends GroupSearchEvent {}

// ===== STATES =====
abstract class GroupSearchState extends Equatable {
  const GroupSearchState();
  @override
  List<Object?> get props => [];
}

class GroupSearchInitial extends GroupSearchState {}

class GroupSearchLoading extends GroupSearchState {}

class GroupSearchLoaded extends GroupSearchState {
  final List<GroupModel> groups;
  final String query;
  const GroupSearchLoaded(this.groups, this.query);
  @override
  List<Object?> get props => [groups, query];
}

class GroupSearchError extends GroupSearchState {
  final String message;
  const GroupSearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class GroupSearchBloc extends Bloc<GroupSearchEvent, GroupSearchState> {
  final GroupRepository _repository;
  Timer? _debounceTimer;

  GroupSearchBloc({required GroupRepository repository})
      : _repository = repository,
        super(GroupSearchInitial()) {
    on<GroupSearchQueryChanged>(_onQueryChanged);
    on<GroupSearchCleared>(_onCleared);
  }

  Future<void> _onQueryChanged(
    GroupSearchQueryChanged event,
    Emitter<GroupSearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(GroupSearchInitial());
      return;
    }

    // Debounce: cancel previous timer
    _debounceTimer?.cancel();

    // Use a completer for debounce in bloc
    emit(GroupSearchLoading());
    try {
      // Small delay for debounce effect
      await Future.delayed(const Duration(milliseconds: 300));
      final groups = await _repository.searchGroups(query);
      emit(GroupSearchLoaded(groups, query));
    } catch (e) {
      emit(GroupSearchError(e.toString()));
    }
  }

  Future<void> _onCleared(
    GroupSearchCleared event,
    Emitter<GroupSearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    emit(GroupSearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
