import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository.dart';

// ===== EVENTS =====
abstract class GroupDetailEvent extends Equatable {
  const GroupDetailEvent();
  @override
  List<Object?> get props => [];
}

class GroupDetailLoadRequested extends GroupDetailEvent {
  final String groupId;
  const GroupDetailLoadRequested(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class GroupDetailAddMembers extends GroupDetailEvent {
  final String groupId;
  final List<String> memberIds;
  const GroupDetailAddMembers(this.groupId, this.memberIds);
  @override
  List<Object?> get props => [groupId, memberIds];
}

class GroupDetailRemoveMember extends GroupDetailEvent {
  final String groupId;
  final String userId;
  const GroupDetailRemoveMember(this.groupId, this.userId);
  @override
  List<Object?> get props => [groupId, userId];
}

class GroupDetailUpdate extends GroupDetailEvent {
  final String groupId;
  final Map<String, dynamic> data;
  const GroupDetailUpdate(this.groupId, this.data);
  @override
  List<Object?> get props => [groupId, data];
}

// ===== STATES =====
abstract class GroupDetailState extends Equatable {
  const GroupDetailState();
  @override
  List<Object?> get props => [];
}

class GroupDetailInitial extends GroupDetailState {}

class GroupDetailLoading extends GroupDetailState {}

class GroupDetailLoaded extends GroupDetailState {
  final GroupModel group;
  const GroupDetailLoaded(this.group);
  @override
  List<Object?> get props => [group];
}

class GroupDetailError extends GroupDetailState {
  final String message;
  const GroupDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupDetailActionSuccess extends GroupDetailState {
  final GroupModel group;
  final String message;
  const GroupDetailActionSuccess(this.group, this.message);
  @override
  List<Object?> get props => [group, message];
}

// ===== BLOC =====
class GroupDetailBloc extends Bloc<GroupDetailEvent, GroupDetailState> {
  final GroupRepository _repository;

  GroupDetailBloc({required GroupRepository repository})
      : _repository = repository,
        super(GroupDetailInitial()) {
    on<GroupDetailLoadRequested>(_onLoad);
    on<GroupDetailAddMembers>(_onAddMembers);
    on<GroupDetailRemoveMember>(_onRemoveMember);
    on<GroupDetailUpdate>(_onUpdate);
  }

  Future<void> _onLoad(
    GroupDetailLoadRequested event,
    Emitter<GroupDetailState> emit,
  ) async {
    emit(GroupDetailLoading());
    try {
      final group = await _repository.getGroupById(event.groupId);
      emit(GroupDetailLoaded(group));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }

  Future<void> _onAddMembers(
    GroupDetailAddMembers event,
    Emitter<GroupDetailState> emit,
  ) async {
    try {
      final group = await _repository.addMembers(event.groupId, event.memberIds);
      emit(GroupDetailActionSuccess(group, 'Thêm thành viên thành công'));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }

  Future<void> _onRemoveMember(
    GroupDetailRemoveMember event,
    Emitter<GroupDetailState> emit,
  ) async {
    try {
      final group = await _repository.removeMember(event.groupId, event.userId);
      emit(GroupDetailActionSuccess(group, 'Xóa thành viên thành công'));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    GroupDetailUpdate event,
    Emitter<GroupDetailState> emit,
  ) async {
    try {
      final group = await _repository.updateGroup(event.groupId, event.data);
      emit(GroupDetailActionSuccess(group, 'Cập nhật nhóm thành công'));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }
}
