import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/feed_repository.dart';

// ===== EVENTS =====
abstract class FeedEvent extends Equatable {
  const FeedEvent();
  @override
  List<Object?> get props => [];
}

class FeedLoadRequested extends FeedEvent {
  final String filter;
  const FeedLoadRequested({this.filter = 'all'});
  @override
  List<Object?> get props => [filter];
}

class FeedLoadMoreRequested extends FeedEvent {
  const FeedLoadMoreRequested();
}

class FeedRefreshRequested extends FeedEvent {
  const FeedRefreshRequested();
}

class FeedFilterChanged extends FeedEvent {
  final String filter;
  const FeedFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class FeedPostLikeToggled extends FeedEvent {
  final String postId;
  const FeedPostLikeToggled(this.postId);
  @override
  List<Object?> get props => [postId];
}

class FeedPostDeleted extends FeedEvent {
  final String postId;
  const FeedPostDeleted(this.postId);
  @override
  List<Object?> get props => [postId];
}

class FeedNewPostCreated extends FeedEvent {
  final PostModel post;
  const FeedNewPostCreated(this.post);
  @override
  List<Object?> get props => [post];
}

// ===== STATES =====
abstract class FeedState extends Equatable {
  const FeedState();
  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<PostModel> posts;
  final bool hasMore;
  final int currentPage;
  final String filter;
  final bool isLoadingMore;

  const FeedLoaded({
    required this.posts,
    this.hasMore = false,
    this.currentPage = 1,
    this.filter = 'all',
    this.isLoadingMore = false,
  });

  FeedLoaded copyWith({
    List<PostModel>? posts,
    bool? hasMore,
    int? currentPage,
    String? filter,
    bool? isLoadingMore,
  }) {
    return FeedLoaded(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [posts, hasMore, currentPage, filter, isLoadingMore];
}

class FeedError extends FeedState {
  final String message;
  const FeedError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _repository;

  FeedBloc({required FeedRepository repository})
      : _repository = repository,
        super(FeedInitial()) {
    on<FeedLoadRequested>(_onLoad);
    on<FeedLoadMoreRequested>(_onLoadMore);
    on<FeedRefreshRequested>(_onRefresh);
    on<FeedFilterChanged>(_onFilterChanged);
    on<FeedPostLikeToggled>(_onLikeToggled);
    on<FeedPostDeleted>(_onPostDeleted);
    on<FeedNewPostCreated>(_onNewPostCreated);
  }

  Future<void> _onLoad(FeedLoadRequested event, Emitter<FeedState> emit) async {
    emit(FeedLoading());
    try {
      final response = await _repository.getFeed(filter: event.filter);
      emit(FeedLoaded(
        posts: response.posts,
        hasMore: response.hasMore,
        currentPage: response.page,
        filter: event.filter,
      ));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onLoadMore(FeedLoadMoreRequested event, Emitter<FeedState> emit) async {
    final currentState = state;
    if (currentState is! FeedLoaded || !currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final response = await _repository.getFeed(
        filter: currentState.filter,
        page: currentState.currentPage + 1,
      );
      emit(currentState.copyWith(
        posts: [...currentState.posts, ...response.posts],
        hasMore: response.hasMore,
        currentPage: response.page,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onRefresh(FeedRefreshRequested event, Emitter<FeedState> emit) async {
    final currentState = state;
    final filter = currentState is FeedLoaded ? currentState.filter : 'all';

    try {
      final response = await _repository.getFeed(filter: filter);
      emit(FeedLoaded(
        posts: response.posts,
        hasMore: response.hasMore,
        currentPage: response.page,
        filter: filter,
      ));
    } catch (_) {
      // Keep current state on refresh failure
    }
  }

  Future<void> _onFilterChanged(FeedFilterChanged event, Emitter<FeedState> emit) async {
    emit(FeedLoading());
    try {
      final response = await _repository.getFeed(filter: event.filter);
      emit(FeedLoaded(
        posts: response.posts,
        hasMore: response.hasMore,
        currentPage: response.page,
        filter: event.filter,
      ));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onLikeToggled(FeedPostLikeToggled event, Emitter<FeedState> emit) async {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    // Optimistic update
    final posts = currentState.posts.map((post) {
      if (post.id == event.postId) {
        return post.copyWith(
          isLiked: !post.isLiked,
          likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );
      }
      return post;
    }).toList();
    emit(currentState.copyWith(posts: posts));

    try {
      final response = await _repository.toggleLike(event.postId);
      // Update with server response
      final serverPosts = (state as FeedLoaded).posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(
            isLiked: response.liked,
            likesCount: response.likesCount,
          );
        }
        return post;
      }).toList();
      emit((state as FeedLoaded).copyWith(posts: serverPosts));
    } catch (_) {
      // Revert optimistic update
      emit(currentState);
    }
  }

  Future<void> _onPostDeleted(FeedPostDeleted event, Emitter<FeedState> emit) async {
    final currentState = state;
    if (currentState is! FeedLoaded) return;

    try {
      await _repository.deletePost(event.postId);
      final posts = currentState.posts.where((p) => p.id != event.postId).toList();
      emit(currentState.copyWith(posts: posts));
    } catch (_) {}
  }

  Future<void> _onNewPostCreated(FeedNewPostCreated event, Emitter<FeedState> emit) async {
    final currentState = state;
    if (currentState is FeedLoaded) {
      emit(currentState.copyWith(
        posts: [event.post, ...currentState.posts],
      ));
    }
  }
}
