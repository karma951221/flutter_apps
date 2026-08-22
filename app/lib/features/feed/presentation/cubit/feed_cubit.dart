import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../post/domain/entity/post.dart';
import '../../domain/usecase/feed_use_case.dart';
import 'feed_state.dart';

/// 피드 목록을 소유한다.
///
/// 게시물 변경은 post feature 가 수행하고, 그 결과만 여기로 반영한다
/// ([prependPost] / [replacePost] / [removePost]). 변경마다 전체를 다시
/// 불러오면 스크롤 위치와 읽던 자리가 사라진다.
@injectable
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._useCase) : super(const FeedState());

  static const _pageSize = 20;

  final FeedUseCase _useCase;

  Future<void> load() async {
    emit(const FeedState());
    final result = await _useCase.getFeedPosts(limit: _pageSize);
    if (isClosed) return;

    emit(
      result.when(
        ok: (page) => FeedState(
          status: FeedStatus.loaded,
          posts: page.items,
          nextCursor: page.nextCursor,
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
      cursor: current.nextCursor,
    );
    if (isClosed) return;

    emit(
      result.when(
        ok: (page) => current.copyWith(
          posts: [...current.posts, ...page.items],
          isLoadingMore: false,
          nextCursor: page.nextCursor,
        ),
        err: (_) => current.copyWith(isLoadingMore: false),
      ),
    );
  }

  /// 새로 작성된 게시물을 목록 맨 앞에 넣는다.
  void prependPost(Post post) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(current.copyWith(posts: [post, ...current.posts]));
  }

  /// 수정된 게시물을 목록에 반영한다.
  void replacePost(Post post) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(
      current.copyWith(
        posts: [
          for (final item in current.posts)
            if (item.id == post.id) post else item,
        ],
      ),
    );
  }

  /// 삭제된 게시물을 목록에서 뺀다.
  void removePost(String postId) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(
      current.copyWith(
        posts: current.posts.where((post) => post.id != postId).toList(),
      ),
    );
  }
}
