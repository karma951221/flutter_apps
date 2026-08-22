import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../../domain/entity/feed_post.dart';
import '../../domain/entity/feed_post_draft.dart';
import '../../domain/entity/feed_post_update.dart';
import '../../domain/usecase/feed_use_case.dart';
import 'feed_state.dart';

@injectable
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._useCase) : super(const FeedState());

  static const _pageSize = 20;

  final FeedUseCase _useCase;

  Future<void> load() async {
    emit(const FeedState());
    final result = await _useCase.getFeedPosts(limit: _pageSize);
    emit(
      result.when(
        ok: (posts) => FeedState(
          status: FeedStatus.loaded,
          posts: posts,
          canLoadMore: posts.length == _pageSize,
        ),
        err: (failure) =>
            FeedState(status: FeedStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    final current = state;
    if (current.status != FeedStatus.loaded ||
        current.isLoadingMore ||
        !current.canLoadMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    final result = await _useCase.getFeedPosts(
      limit: _pageSize,
      offset: current.posts.length,
    );
    emit(
      result.when(
        ok: (posts) => current.copyWith(
          posts: [...current.posts, ...posts],
          isLoadingMore: false,
          canLoadMore: posts.length == _pageSize,
        ),
        err: (_) => current.copyWith(isLoadingMore: false),
      ),
    );
  }

  Future<Result<FeedPost>> create(String content) async {
    final result = await _useCase.createFeedPost(
      FeedPostDraft(content: content),
    );
    final current = state;
    if (current.status == FeedStatus.loaded) {
      result.when(
        ok: (post) => emit(current.copyWith(posts: [post, ...current.posts])),
        err: (_) {},
      );
    }
    return result;
  }

  Future<Result<FeedPost>> update(String postId, String content) async {
    final result = await _useCase.updateFeedPost(
      postId,
      FeedPostUpdate(content: content),
    );
    final current = state;
    if (current.status == FeedStatus.loaded) {
      result.when(
        ok: (updated) => emit(
          current.copyWith(
            posts: [
              for (final post in current.posts)
                if (post.id == updated.id) updated else post,
            ],
          ),
        ),
        err: (_) {},
      );
    }
    return result;
  }

  Future<Result<void>> delete(String postId) async {
    final result = await _useCase.deleteFeedPost(postId);
    final current = state;
    if (current.status == FeedStatus.loaded) {
      result.when(
        ok: (_) => emit(
          current.copyWith(
            posts: current.posts.where((post) => post.id != postId).toList(),
          ),
        ),
        err: (_) {},
      );
    }
    return result;
  }
}
