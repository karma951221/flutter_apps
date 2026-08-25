import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post.dart';
import '../../../reaction/domain/entity/reaction_summary.dart';
import '../../../reaction/domain/entity/reaction_target.dart';
import '../../../reaction/domain/entity/reaction_type.dart';
import '../../../reaction/domain/usecase/reaction_use_case.dart';
import '../../domain/entity/feed_post.dart';
import '../../domain/usecase/feed_use_case.dart';
import 'feed_state.dart';

/// 피드 목록을 소유한다.
///
/// 게시물 변경은 post feature 가 수행하고, 그 결과만 여기로 반영한다
/// ([prependPost] / [replacePost] / [removePost]). 변경마다 전체를 다시
/// 불러오면 스크롤 위치와 읽던 자리가 사라진다.
///
/// 감정표현만 예외로 여기서 직접 저장한다 ([toggleReaction]). 반응 전용
/// Bloc 을 두지 않기 때문이다 — 반응 상태는 목록 항목 안에 살고, 낙관적
/// 업데이트와 실패 복원은 목록을 소유한 쪽만 할 수 있다
/// (docs/features/reaction/plan.md).
@injectable
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._useCase, this._reactionUseCase) : super(const FeedState());

  static const _pageSize = 20;

  final FeedUseCase _useCase;
  final ReactionUseCase _reactionUseCase;
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

  /// 차단한 작성자의 게시물을 모두 목록에서 뺀다.
  ///
  /// 다시 읽지 않는다 — 재조회는 스크롤 위치를 지운다. 서버가 이미 그 작성자의
  /// 글을 가려주므로(양방향 차단 필터), 여기서는 이미 그려진 항목만 걷어내면
  /// 된다.
  void removeAuthor(String authorId) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(
      current.copyWith(
        items: current.items
            .where((item) => item.author.id != authorId)
            .toList(),
      ),
    );
  }

  /// 반응 결과를 해당 항목에만 반영한다.
  ///
  /// 낙관적 업데이트의 두 방향이 모두 이 메서드를 쓴다 — 탭 직후에는 계산된
  /// 다음 상태를, 실패하면 이전 상태를 넣는다. 목록 상태는 목록이 소유한다
  /// (아키텍처 규칙 ⑥).
  void applyReaction(String postId, ReactionSummary next) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.id == postId) item.withReactions(next) else item,
        ],
      ),
    );
  }

  /// 감정을 눌러 저장하고 목록에 반영한다.
  ///
  /// 탭 직후에 계산된 다음 상태를 먼저 그리고, 저장이 실패하면 이전 값으로
  /// 되돌린다. 화면은 돌려받은 Result 로 실패만 알린다.
  Future<Result<ReactionSummary>> toggleReaction(
    String postId,
    ReactionType tapped,
  ) async {
    final current = state;
    if (current.status != FeedStatus.loaded) {
      return const Err(Failure.validation(message: '목록을 먼저 읽어야 합니다'));
    }

    final index = current.items.indexWhere((item) => item.id == postId);
    if (index < 0) {
      return const Err(Failure.notFound(message: '게시물을 찾을 수 없습니다'));
    }

    final previous = current.items[index].reactions;
    applyReaction(postId, previous.toggled(tapped));

    final result = await _reactionUseCase.toggle(
      target: ReactionTarget.post(postId),
      tapped: tapped,
      current: previous,
    );
    if (isClosed) return result;

    result.when(
      ok: (next) => applyReaction(postId, next),
      err: (_) => applyReaction(postId, previous),
    );
    return result;
  }

  /// 댓글 수를 해당 항목에만 반영한다. 댓글 화면에서 돌아올 때 목록을 다시
  /// 읽지 않기 위해서다.
  void applyCommentCount(String postId, int count) {
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    emit(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.id == postId)
              FeedPost(
                post: item.post,
                author: item.author,
                reactions: item.reactions,
                commentCount: count,
              )
            else
              item,
        ],
      ),
    );
  }
}
