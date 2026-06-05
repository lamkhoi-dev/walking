import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/friendship_model.dart';
import '../../data/repositories/friend_repository.dart';

// === EVENTS ===

abstract class FriendEvent {
  const FriendEvent();
}

class FriendLoadFriends extends FriendEvent {
  final int page;
  final String? search;
  const FriendLoadFriends({this.page = 1, this.search});
}

class FriendLoadRequests extends FriendEvent {
  const FriendLoadRequests();
}

class FriendSendRequest extends FriendEvent {
  final String userId;
  const FriendSendRequest(this.userId);
}

class FriendAcceptRequest extends FriendEvent {
  final String friendshipId;
  const FriendAcceptRequest(this.friendshipId);
}

class FriendRejectRequest extends FriendEvent {
  final String friendshipId;
  const FriendRejectRequest(this.friendshipId);
}

class FriendCancelRequest extends FriendEvent {
  final String friendshipId;
  const FriendCancelRequest(this.friendshipId);
}

class FriendUnfriend extends FriendEvent {
  final String friendId;
  const FriendUnfriend(this.friendId);
}

class FriendSearchUsers extends FriendEvent {
  final String query;
  final int page;
  const FriendSearchUsers(this.query, {this.page = 1});
}

class FriendLoadProfile extends FriendEvent {
  final String userId;
  const FriendLoadProfile(this.userId);
}

// === STATES ===

abstract class FriendState {
  const FriendState();
}

class FriendInitial extends FriendState {}

class FriendLoading extends FriendState {}

class FriendFriendsLoaded extends FriendState {
  final List<FriendUser> friends;
  final Map<String, dynamic> pagination;

  const FriendFriendsLoaded({required this.friends, required this.pagination});
}

class FriendRequestsLoaded extends FriendState {
  final List<FriendRequest> requests;
  final Map<String, dynamic> pagination;

  const FriendRequestsLoaded({required this.requests, required this.pagination});
}

class FriendSearchResults extends FriendState {
  final List<FriendUser> users;
  final Map<String, dynamic> pagination;

  const FriendSearchResults({required this.users, required this.pagination});
}

class FriendProfileLoaded extends FriendState {
  final UserProfile profile;

  const FriendProfileLoaded(this.profile);
}

class FriendActionSuccess extends FriendState {
  final String message;
  const FriendActionSuccess(this.message);
}

class FriendError extends FriendState {
  final String message;
  const FriendError(this.message);
}

// === BLOC ===

class FriendBloc extends Bloc<FriendEvent, FriendState> {
  final FriendRepository repository;

  FriendBloc({required this.repository}) : super(FriendInitial()) {
    on<FriendLoadFriends>(_onLoadFriends);
    on<FriendLoadRequests>(_onLoadRequests);
    on<FriendSendRequest>(_onSendRequest);
    on<FriendAcceptRequest>(_onAcceptRequest);
    on<FriendRejectRequest>(_onRejectRequest);
    on<FriendCancelRequest>(_onCancelRequest);
    on<FriendUnfriend>(_onUnfriend);
    on<FriendSearchUsers>(_onSearchUsers);
    on<FriendLoadProfile>(_onLoadProfile);
  }

  Future<void> _onLoadFriends(FriendLoadFriends event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final result = await repository.getFriends(
        page: event.page,
        search: event.search,
      );
      emit(FriendFriendsLoaded(
        friends: result['friends'] as List<FriendUser>,
        pagination: result['pagination'] as Map<String, dynamic>,
      ));
    } catch (e) {
      debugPrint('FriendBloc: loadFriends error: $e');
      emit(FriendError(e.toString()));
    }
  }

  Future<void> _onLoadRequests(FriendLoadRequests event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final result = await repository.getFriendRequests();
      emit(FriendRequestsLoaded(
        requests: result['requests'] as List<FriendRequest>,
        pagination: result['pagination'] as Map<String, dynamic>,
      ));
    } catch (e) {
      debugPrint('FriendBloc: loadRequests error: $e');
      emit(FriendError(e.toString()));
    }
  }

  Future<void> _onSendRequest(FriendSendRequest event, Emitter<FriendState> emit) async {
    try {
      await repository.sendRequest(event.userId);
      emit(const FriendActionSuccess('friend.request_sent_success'));
    } catch (e) {
      debugPrint('FriendBloc: sendRequest error: $e');
      emit(FriendError(e.toString()));
    }
  }

  Future<void> _onAcceptRequest(FriendAcceptRequest event, Emitter<FriendState> emit) async {
    try {
      await repository.acceptRequest(event.friendshipId);
      emit(const FriendActionSuccess('friend.accept_success'));
    } catch (e) {
      debugPrint('FriendBloc: acceptRequest error: $e');
      emit(FriendError(e.toString()));
    }
  }

  Future<void> _onRejectRequest(FriendRejectRequest event, Emitter<FriendState> emit) async {
    try {
      await repository.rejectRequest(event.friendshipId);
      emit(const FriendActionSuccess('friend.reject_success'));
    } catch (e) {
      debugPrint('FriendBloc: rejectRequest error: $e');
      emit(FriendError(e.toString()));
    }
  }

  Future<void> _onCancelRequest(FriendCancelRequest event, Emitter<FriendState> emit) async {
    try {
      await repository.cancelRequest(event.friendshipId);
      emit(const FriendActionSuccess('friend.cancel_request'));
    } catch (e) {
      debugPrint('FriendBloc: cancelRequest error: $e');
      emit(FriendError(e.toString()));
    }
  }

  Future<void> _onUnfriend(FriendUnfriend event, Emitter<FriendState> emit) async {
    try {
      await repository.unfriend(event.friendId);
      emit(const FriendActionSuccess('friend.unfriend_success'));
    } catch (e) {
      debugPrint('FriendBloc: unfriend error: $e');
      emit(FriendError(e.toString()));
    }
  }

  Future<void> _onSearchUsers(FriendSearchUsers event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final result = await repository.searchUsers(
        query: event.query,
        page: event.page,
      );
      emit(FriendSearchResults(
        users: result['users'] as List<FriendUser>,
        pagination: result['pagination'] as Map<String, dynamic>,
      ));
    } catch (e) {
      debugPrint('FriendBloc: searchUsers error: $e');
      emit(FriendError(e.toString()));
    }
  }

  Future<void> _onLoadProfile(FriendLoadProfile event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final profile = await repository.getUserProfile(event.userId);
      emit(FriendProfileLoaded(profile));
    } catch (e) {
      debugPrint('FriendBloc: loadProfile error: $e');
      emit(FriendError(e.toString()));
    }
  }
}
