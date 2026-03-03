import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository.dart';

// ===== EVENTS =====
abstract class GroupListEvent extends Equatable {
  const GroupListEvent();
  @override
  List<Object?> get props => [];
}

class GroupListLoadRequested extends GroupListEvent {}

class GroupListRefreshRequested extends GroupListEvent {}

class GroupDeleteRequested extends GroupListEvent {
  final String groupId;
  const GroupDeleteRequested(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

// ===== STATES =====
abstract class GroupListState extends Equatable {
  const GroupListState();
  @override
  List<Object?> get props => [];
}

class GroupListInitial extends GroupListState {}

class GroupListLoading extends GroupListState {}

class GroupListLoaded extends GroupListState {
  final List<GroupModel> groups;
  const GroupListLoaded(this.groups);
  @override
  List<Object?> get props => [groups];
}

class GroupListError extends GroupListState {
  final String message;
  const GroupListError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class GroupListBloc extends Bloc<GroupListEvent, GroupListState> {
  final GroupRepository _repository;

  GroupListBloc({required GroupRepository repository})
      : _repository = repository,
        super(GroupListInitial()) {
    on<GroupListLoadRequested>(_onLoad);
    on<GroupListRefreshRequested>(_onRefresh);
    on<GroupDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    GroupListLoadRequested event,
    Emitter<GroupListState> emit,
  ) async {
    emit(GroupListLoading());
    try {
      final groups = await _repository.getGroups();
      emit(GroupListLoaded(groups));
    } catch (e) {
      emit(GroupListError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    GroupListRefreshRequested event,
    Emitter<GroupListState> emit,
  ) async {
    try {
      final groups = await _repository.getGroups();
      emit(GroupListLoaded(groups));
    } catch (e) {
      emit(GroupListError(e.toString()));
    }
  }

  Future<void> _onDelete(
    GroupDeleteRequested event,
    Emitter<GroupListState> emit,
  ) async {
    try {
      await _repository.deleteGroup(event.groupId);
      // Reload list after deletion
      final groups = await _repository.getGroups();
      emit(GroupListLoaded(groups));
    } catch (e) {
      emit(GroupListError(e.toString()));
    }
  }
}
