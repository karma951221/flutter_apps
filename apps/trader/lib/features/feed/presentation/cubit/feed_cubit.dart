import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_code.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post.dart';
import '../../../post/domain/entity/post_author.dart';
import '../../../reaction/domain/entity/reaction_summary.dart';
import '../../../reaction/domain/entity/reaction_target.dart';
import '../../../reaction/domain/entity/reaction_type.dart';
import '../../../reaction/domain/usecase/reaction_use_case.dart';
import '../../domain/entity/feed_post.dart';
import '../../domain/entity/feed_source.dart';
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
  FeedSource _source = FeedSource.all;

  /// 이번 조회(`_load()`) 동안 걷어낸 작성자 id 들.
  ///
  /// `loadMore()`는 요청을 보낸 뒤에 응답이 돌아오므로, 그 사이에 차단이
  /// 걸리면 두 군데서 새어 들어올 수 있다 — (a) 진행 중이던 다른 mutator가
  /// 반영한 값이 `loadMore`가 들고 있던 스냅샷에 덮여 사라지는 것, (b) 요청을
  /// 이미 보낸 뒤라 응답 페이지 자체에 그 작성자의 글이 그대로 담겨 오는
  /// 것. `removeAuthor`가 여기 id를 쌓아 두고, `loadMore`가 최신 `state`에
  /// 병합하면서 들어오는 페이지도 이 집합으로 한 번 더 거른다. 새로
  /// `_load()`를 하면 서버가 이미 걸러 주므로 비운다.
  final _hiddenAuthorIds = <String>{};

  /// 생성 이벤트 구독. 화면이 [watchCreatedPosts] 로 심고 [close] 에서 걷는다.
  StreamSubscription<Post>? _createdPostsSubscription;

  /// 지금 화면이 기다리고 있는 조회의 세대 번호.
  ///
  /// 소스(전체 · 팔로잉 · 작성자)는 요청을 보낼 때 읽히지만, 응답은 그보다
  /// 늦게 온다. 그 사이에 탭을 옮기면 앞 소스의 응답이 새 탭의 목록으로
  /// 그대로 들어앉는다 — `isClosed` 는 cubit 이 살아 있는 동안의 이 엇갈림을
  /// 막지 못한다. `_load()` 가 이 번호를 올리고, 요청을 띄우는 쪽은 보내기
  /// 전에 번호를 잡아 두었다가 응답 시점에 달라졌으면 버린다.
  ///
  /// `loadMore` 가 띄운 요청이 돌아오기 전에 `_load()` 가 끼어드는 경우도 같은
  /// 검사로 걷힌다 — 그때는 `isLoadingMore` 가 이미 초기화돼 있어 다음 페이지
  /// 요청이 겹쳐 나갈 수 있는 자리이기도 하다.
  int _generation = 0;

  Future<void> load() async {
    _authorId = null;
    _source = FeedSource.all;
    await _load();
  }

  /// 팔로우한 사람들의 글만 읽는다. 화면·커서·항목 모양은 전체 피드와 같고
  /// 읽는 뷰만 바뀐다 (docs/features/follow/plan.md).
  Future<void> loadFollowing() async {
    _authorId = null;
    _source = FeedSource.following;
    await _load();
  }

  Future<void> loadForAuthor(String authorId) async {
    _authorId = authorId;
    // 프로필의 목록은 언제나 전체 소스다 — 그 사람을 팔로우했는지와 무관하게
    // 그 사람의 글을 보여주는 자리다.
    _source = FeedSource.all;
    await _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    // 새로 불러오는 순간부터는 서버(양방향 차단 필터)가 이미 걸러 주므로,
    // 지난 조회 동안 쌓인 걷어냄 목록은 의미가 없다.
    _hiddenAuthorIds.clear();
    emit(const FeedState());
    final result = await _useCase.getFeedPosts(
      limit: _pageSize,
      authorId: _authorId,
      source: _source,
    );
    if (isClosed || generation != _generation) return;

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

    final generation = _generation;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _useCase.getFeedPosts(
      limit: _pageSize,
      cursor: current.nextCursor,
      authorId: _authorId,
      source: _source,
    );
    // 세대가 바뀌었다면 이 페이지는 지난 소스의 것이다. 최신 state 에 붙이면
    // 새 탭의 목록에 남의 소스 항목이 이어지고 커서까지 그쪽 것으로 덮인다.
    if (isClosed || generation != _generation) return;

    // 요청이 날아가 있는 동안 다른 mutator(예: removeAuthor)가 state를 바꿨을
    // 수 있다. current(요청 전 스냅샷)가 아니라 지금의 state 위에 병합해야
    // 그 변경을 덮어쓰지 않는다. 요청 자체는 차단 전에 나갔을 수 있으므로
    // 응답 페이지에도 이미 걷어낸 작성자의 글이 그대로 담겨 올 수 있다 —
    // 들어오는 페이지도 같은 집합으로 거른다.
    final latest = state;
    emit(
      result.when(
        ok: (page) => latest.copyWith(
          items: [
            ...latest.items,
            ...page.items.where(
              (item) => !_hiddenAuthorIds.contains(item.author.id),
            ),
          ],
          isLoadingMore: false,
          nextCursor: page.nextCursor,
        ),
        err: (_) => latest.copyWith(isLoadingMore: false),
      ),
    );
  }

  /// 새로 작성된 게시물을 목록 맨 앞에 넣는다.
  ///
  /// 작성자는 로그인한 본인이므로 화면이 세션에서 만들어 넘긴다. 이것 하나를
  /// 위해 방금 쓴 글을 서버에서 다시 조회하지 않는다.
  ///
  /// 팔로잉 소스에서는 넣지 않는다. `following_posts_with_author` 는 follows
  /// 를 조인하고 `follows_not_self` 가 자기 팔로우를 막으므로, 내 글은 이
  /// 목록에 절대 들어올 수 없다 — 넣어 두면 맨 위에 보였다가 새로고침 한 번에
  /// 사라져 글이 날아간 것처럼 보인다. 화면이 소스를 다시 판단하게 하지 않고
  /// 목록을 소유한 여기서 막는다.
  void prependPost(FeedPost item) {
    if (_source == FeedSource.following) return;
    final current = state;
    if (current.status != FeedStatus.loaded) return;
    // 같은 글이 두 경로로 들어올 수 있다 — 작성 화면이 돌려준 값으로 넣는
    // 기존 경로와 [watchCreatedPosts] 의 생성 이벤트. 두 번 붙이면 목록에
    // 같은 글이 두 장 그려지므로 이미 있으면 넘긴다.
    if (current.items.any((existing) => existing.id == item.id)) return;
    emit(current.copyWith(items: [item, ...current.items]));
  }

  /// 이 세션에서 새로 작성되는 게시물을 목록 맨 앞에 붙인다.
  ///
  /// 작성 화면을 목록이 아닌 곳(예: 매매 결과 화면)에서 띄우면 반환값이
  /// 목록까지 오지 않는다. 그래도 홈 셸 안에 살아 있는 이 목록은 갱신돼야
  /// 하므로 생성 사실을 직접 듣는다. [author] 는 로그인한 본인이다 — 화면이
  /// 세션 값으로 만들어 넘긴다 ([prependPost] 와 같은 이유).
  void watchCreatedPosts(PostAuthor author) {
    _createdPostsSubscription?.cancel();
    _createdPostsSubscription = _useCase.createdPosts.listen((post) {
      // 남의 글은 이 경로로 오지 않지만, 와도 본인 이름표를 붙이지 않는다.
      if (post.authorId != author.id) return;
      // 남의 프로필 목록을 보고 있으면 내 글이 낄 자리가 아니다.
      if (_authorId != null && _authorId != post.authorId) return;
      prependPost(FeedPost(post: post, author: author));
    });
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
    _hiddenAuthorIds.add(authorId);
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
      return const Err(
        Failure.validation(
          message: '목록을 먼저 읽어야 합니다',
          failureCode: FailureCode.feedNotLoaded,
        ),
      );
    }

    final index = current.items.indexWhere((item) => item.id == postId);
    if (index < 0) {
      return const Err(
        Failure.notFound(
          message: '게시물을 찾을 수 없습니다',
          failureCode: FailureCode.postNotFound,
        ),
      );
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

  @override
  Future<void> close() async {
    await _createdPostsSubscription?.cancel();
    return super.close();
  }
}
