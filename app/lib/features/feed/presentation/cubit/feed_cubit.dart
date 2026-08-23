import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../post/domain/entity/post.dart';
import '../../domain/entity/feed_post.dart';
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
  String? _authorId;

  Future<void> load() async {
    _authorId = null;
    await _load();
  }

  Future<void> loadForAuthor(String authorId) async {
    _authorId = authorId;
    await _load();
  }

  Future<void> _load() async {
    emit(const FeedState());
    final result = await _useCase.getFeedPosts(
      limit: _pageSize,
      authorId: _authorId,
    );
    if (isClosed) return;

    emit(
      result.when(
        ok: (page) => FeedState(
          status: FeedStatus.loaded,
          items: page.items,
          nextCursor: page.nextCursor,
        ),
        err: (failure) =>
            FeedState(status: FeedStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> refresh() => _load();

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
      authorId: _authorId,
    );
    if (isClosed) return;

    emit(
      result.when(
        ok: (page) => current.copyWith(
          items: [...current.items, ...page.items],
          isLoadingMore: false,
          nextCursor: page.nextCursor,
        ),
        err: (_) => current.copyWith(isLoadingMore: false),
      ),
    );
  }

  /// 새로 작성된 게시물을 목록 맨 앞에 넣는다.
  ///
  /// 작성자는 로그인한 본인이므로 화면이 세션에서 만들어 넘긴다. 이것 하나를
  /// 위해 방금 쓴 글을 서버에서 다시 조회하지 않는다.
  void prependPost(FeedPost item) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(current.copyWith(items: [item, ...current.items]));
  }

  /// 수정된 게시물을 목록에 반영한다.
  ///
  /// 작성자는 수정으로 바뀌지 않으므로 목록이 이미 들고 있던 값을 그대로 둔다.
  /// 수정 화면이 작성자 프로필을 알 필요가 없다는 뜻이기도 하다.
  void replacePost(Post post) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.id == post.id) item.withPost(post) else item,
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
        items: current.items.where((item) => item.id != postId).toList(),
      ),
    );
  }
}
