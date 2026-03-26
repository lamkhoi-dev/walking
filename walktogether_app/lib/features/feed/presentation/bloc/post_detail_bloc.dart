import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/feed_repository.dart';

// ===== EVENTS =====
abstract class PostDetailEvent extends Equatable {
  const PostDetailEvent();
  @override
  List<Object?> get props => [];
}

class PostDetailLoadRequested extends PostDetailEvent {
  final String postId;
  const PostDetailLoadRequested(this.postId);
  @override
  List<Object?> get props => [postId];
}

class PostDetailLikeToggled extends PostDetailEvent {
  const PostDetailLikeToggled();
}

class PostDetailCommentSubmitted extends PostDetailEvent {
  final String content;
  const PostDetailCommentSubmitted(this.content);
  @override
  List<Object?> get props => [content];
}

class PostDetailCommentDeleted extends PostDetailEvent {
  final String commentId;
  const PostDetailCommentDeleted(this.commentId);
  @override
  List<Object?> get props => [commentId];
}

class PostDetailCommentsLoadMore extends PostDetailEvent {
  const PostDetailCommentsLoadMore();
}

// ===== STATES =====
abstract class PostDetailState extends Equatable {
  const PostDetailState();
  @override
  List<Object?> get props => [];
}

class PostDetailInitial extends PostDetailState {}

class PostDetailLoading extends PostDetailState {}

class PostDetailLoaded extends PostDetailState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool hasMoreComments;
  final int commentsPage;
  final bool isSubmittingComment;
  final bool isLoadingMoreComments;

  const PostDetailLoaded({
    required this.post,
    this.comments = const [],
    this.hasMoreComments = false,
    this.commentsPage = 1,
    this.isSubmittingComment = false,
    this.isLoadingMoreComments = false,
  });

  PostDetailLoaded copyWith({
    PostModel? post,
    List<CommentModel>? comments,
    bool? hasMoreComments,
    int? commentsPage,
    bool? isSubmittingComment,
    bool? isLoadingMoreComments,
  }) {
    return PostDetailLoaded(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      commentsPage: commentsPage ?? this.commentsPage,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      isLoadingMoreComments: isLoadingMoreComments ?? this.isLoadingMoreComments,
    );
  }

  @override
  List<Object?> get props => [
        post,
        comments,
        hasMoreComments,
        commentsPage,
        isSubmittingComment,
        isLoadingMoreComments,
      ];
}

class PostDetailError extends PostDetailState {
  final String message;
  const PostDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

// ===== BLOC =====
class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  final FeedRepository _repository;
  String? _postId;

  PostDetailBloc({required FeedRepository repository})
      : _repository = repository,
        super(PostDetailInitial()) {
    on<PostDetailLoadRequested>(_onLoad);
    on<PostDetailLikeToggled>(_onLikeToggled);
    on<PostDetailCommentSubmitted>(_onCommentSubmitted);
    on<PostDetailCommentDeleted>(_onCommentDeleted);
    on<PostDetailCommentsLoadMore>(_onLoadMoreComments);
  }

  Future<void> _onLoad(
    PostDetailLoadRequested event,
    Emitter<PostDetailState> emit,
  ) async {
    _postId = event.postId;
    emit(PostDetailLoading());

    try {
      final results = await Future.wait([
        _repository.getPostById(event.postId),
        _repository.getComments(event.postId),
      ]);

      final post = results[0] as PostModel;
      final commentsResponse = results[1] as CommentsResponse;

      emit(PostDetailLoaded(
        post: post,
        comments: commentsResponse.comments,
        hasMoreComments: commentsResponse.hasMore,
        commentsPage: commentsResponse.page,
      ));
    } catch (e) {
      emit(PostDetailError(e.toString()));
    }
  }

  Future<void> _onLikeToggled(
    PostDetailLikeToggled event,
    Emitter<PostDetailState> emit,
  ) async {
    if (state is! PostDetailLoaded || _postId == null) return;
    final current = state as PostDetailLoaded;

    // Optimistic update
    emit(current.copyWith(
      post: current.post.copyWith(
        isLiked: !current.post.isLiked,
        likesCount: current.post.isLiked
            ? current.post.likesCount - 1
            : current.post.likesCount + 1,
      ),
    ));

    try {
      final response = await _repository.toggleLike(_postId!);
      final updated = state as PostDetailLoaded;
      emit(updated.copyWith(
        post: updated.post.copyWith(
          isLiked: response.liked,
          likesCount: response.likesCount,
        ),
      ));
    } catch (_) {
      // Revert
      emit(current);
    }
  }

  Future<void> _onCommentSubmitted(
    PostDetailCommentSubmitted event,
    Emitter<PostDetailState> emit,
  ) async {
    if (state is! PostDetailLoaded || _postId == null) return;
    final current = state as PostDetailLoaded;

    emit(current.copyWith(isSubmittingComment: true));

    try {
      final comment = await _repository.createComment(_postId!, event.content);
      final updated = state as PostDetailLoaded;
      emit(updated.copyWith(
        comments: [comment, ...updated.comments],
        isSubmittingComment: false,
        post: updated.post.copyWith(
          commentsCount: updated.post.commentsCount + 1,
        ),
      ));
    } catch (_) {
      emit((state as PostDetailLoaded).copyWith(isSubmittingComment: false));
    }
  }

  Future<void> _onCommentDeleted(
    PostDetailCommentDeleted event,
    Emitter<PostDetailState> emit,
  ) async {
    if (state is! PostDetailLoaded) return;
    final current = state as PostDetailLoaded;

    // Optimistic remove
    final filtered = current.comments.where((c) => c.id != event.commentId).toList();
    emit(current.copyWith(
      comments: filtered,
      post: current.post.copyWith(
        commentsCount: (current.post.commentsCount - 1).clamp(0, 999999),
      ),
    ));

    try {
      await _repository.deleteComment(event.commentId);
    } catch (_) {
      // Revert
      emit(current);
    }
  }

  Future<void> _onLoadMoreComments(
    PostDetailCommentsLoadMore event,
    Emitter<PostDetailState> emit,
  ) async {
    if (state is! PostDetailLoaded || _postId == null) return;
    final current = state as PostDetailLoaded;
    if (!current.hasMoreComments || current.isLoadingMoreComments) return;

    emit(current.copyWith(isLoadingMoreComments: true));

    try {
      final response = await _repository.getComments(
        _postId!,
        page: current.commentsPage + 1,
      );
      emit(current.copyWith(
        comments: [...current.comments, ...response.comments],
        hasMoreComments: response.hasMore,
        commentsPage: response.page,
        isLoadingMoreComments: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMoreComments: false));
    }
  }
}
