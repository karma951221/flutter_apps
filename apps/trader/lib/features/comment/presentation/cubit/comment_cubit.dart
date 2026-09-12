import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import 'package:feature_post/feature_post.dart';
import 'package:feature_reaction/feature_reaction.dart';
import '../../domain/entity/post_comment.dart';
import '../../domain/usecase/comment_use_case.dart';
import 'comment_state.dart';

/// 한 게시물의 댓글 목록을 소유한다.
///
/// 부모 목록과 답글 목록이 각각 커서 페이지네이션이고, 답글은 부모를 눌렀을 때
/// 읽는다. 작성·삭제·감정 결과는 재조회 없이 이 상태에 반영한다 — 댓글 하나를
/// 쓸 때마다 목록을 다시 읽으면 읽던 자리가 사라진다.
@injectable
class CommentCubit extends Cubit<CommentState> {
  CommentCubit(this._useCase, this._reactionUseCase)
    : super(const CommentState());

  static const _pageSize = 20;

  final CommentUseCase _useCase;
  final ReactionUseCase _reactionUseCase;

  String _postId = '';

  Future<void> load(String postId) async {
    _postId = postId;
    emit(const CommentState());

    final result = await _useCase.getComments(postId: postId, limit: _pageSize);
    if (isClosed) return;

    emit(
      result.when(
        ok: (page) => CommentState(
          status: CommentStatus.loaded,
          items: page.items,
          nextCursor: page.nextCursor,
        ),
        err: (failure) =>
            CommentState(status: CommentStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> refresh() => load(_postId);

  Future<void> loadMore() async {
    final current = state;
    if (current.status != CommentStatus.loaded ||
        current.isLoadingMore ||
        !current.canLoadMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    final result = await _useCase.getComments(
      postId: _postId,
      limit: _pageSize,
      cursor: current.nextCursor,
    );
    if (isClosed) return;

    emit(
      result.when(
        ok: (page) => state.copyWith(
          items: [...state.items, ...page.items],
          isLoadingMore: false,
          nextCursor: page.nextCursor,
        ),
        err: (_) => state.copyWith(isLoadingMore: false),
      ),
    );
  }

  /// 답글을 펼치거나 접는다. 처음 펼칠 때 한 번만 읽는다.
  Future<void> toggleReplies(String parentId) async {
    final current = state;
    if (current.isExpanded(parentId)) {
      emit(
        current.copyWith(
          expandedParentIds: {...current.expandedParentIds}..remove(parentId),
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        expandedParentIds: {...current.expandedParentIds, parentId},
      ),
    );
    if (current.replies.containsKey(parentId)) return;

    await _fetchReplies(parentId, cursor: null);
  }

  Future<void> loadMoreReplies(String parentId) async {
    final cursor = state.replyCursors[parentId];
    if (cursor == null || state.isLoadingReplies(parentId)) return;
    await _fetchReplies(parentId, cursor: cursor);
  }

  Future<void> _fetchReplies(String parentId, {required String? cursor}) async {
    emit(
      state.copyWith(loadingParentIds: {...state.loadingParentIds, parentId}),
    );

    final result = await _useCase.getReplies(
      parentId: parentId,
      limit: _pageSize,
      cursor: cursor,
    );
    if (isClosed) return;

    final loading = {...state.loadingParentIds}..remove(parentId);

    emit(
      result.when(
        ok: (page) => state.copyWith(
          loadingParentIds: loading,
          replies: {
            ...state.replies,
            parentId: [...state.repliesOf(parentId), ...page.items],
          },
          replyCursors: {...state.replyCursors, parentId: page.nextCursor},
        ),
        err: (failure) =>
            state.copyWith(loadingParentIds: loading, failure: failure),
      ),
    );
  }

  /// 댓글 또는 답글을 쓴다.
  ///
  /// 성공하면 서버가 준 id·시각에 화면이 아는 본문·작성자를 붙인 항목을 목록
  /// 끝에 넣는다. 오래된 순 정렬이므로 새 댓글의 자리는 끝이다.
  Future<Result<PostComment>> add({
    required String content,
    required PostAuthor author,
    String? parentId,
  }) async {
    if (state.isSubmitting) {
      return const Err(
        Failure.validation(
          message: '이미 처리 중입니다',
          failureCode: FailureCode.operationInProgress,
        ),
      );
    }

    emit(state.copyWith(isSubmitting: true));
    final result = await _useCase.addComment(
      postId: _postId,
      parentId: parentId,
      content: content,
      author: author,
    );
    if (isClosed) return result;

    emit(state.copyWith(isSubmitting: false));
    result.when(ok: _insert, err: (_) {});
    return result;
  }

  void _insert(PostComment created) {
    final parentId = created.parentId;
    if (parentId == null) {
      emit(
        state.copyWith(
          items: [...state.items, created],
          countDelta: state.countDelta + 1,
        ),
      );
      return;
    }

    // 답글을 달면 부모의 답글 수를 앱에서 하나 올린다. 답글이 이미 펼쳐져
    // 있지 않으면 방금 쓴 것이 보이도록 함께 펼친다.
    emit(
      state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == parentId)
              item.withReplyCount(item.replyCount + 1)
            else
              item,
        ],
        replies: {
          ...state.replies,
          parentId: [...state.repliesOf(parentId), created],
        },
        expandedParentIds: {...state.expandedParentIds, parentId},
        countDelta: state.countDelta + 1,
      ),
    );
  }

  /// 내 댓글을 지운다.
  ///
  /// 답글이 남은 부모는 본문만 가리고 목록에 남긴다. 답글과 답글 없는 부모는
  /// 목록에서 뺀다 — 서버의 `post_comments_visible` 이 하는 판단과 같은 모양을
  /// 앱이 미리 그려서 삭제 직후 재조회를 없앤다.
  Future<Result<bool>> delete(PostComment comment) async {
    if (state.isSubmitting) {
      return const Err(
        Failure.validation(
          message: '이미 처리 중입니다',
          failureCode: FailureCode.operationInProgress,
        ),
      );
    }

    emit(state.copyWith(isSubmitting: true));
    final result = await _useCase.deleteComment(comment.id);
    if (isClosed) return result;

    emit(state.copyWith(isSubmitting: false));
    result.when(
      ok: (deleted) {
        if (deleted) _removeDeleted(comment);
      },
      err: (_) {},
    );
    return result;
  }

  void _removeDeleted(PostComment comment) {
    final parentId = comment.parentId;

    if (parentId != null) {
      emit(
        state.copyWith(
          items: [
            for (final item in state.items)
              if (item.id == parentId)
                item.withReplyCount(
                  item.replyCount > 0 ? item.replyCount - 1 : 0,
                )
              else
                item,
          ],
          replies: {
            ...state.replies,
            parentId: state
                .repliesOf(parentId)
                .where((reply) => reply.id != comment.id)
                .toList(),
          },
          countDelta: state.countDelta - 1,
        ),
      );
      return;
    }

    final hasLiveReplies = comment.replyCount > 0;
    emit(
      state.copyWith(
        items: hasLiveReplies
            ? [
                for (final item in state.items)
                  if (item.id == comment.id)
                    item.asDeleted(DateTime.now().toUtc())
                  else
                    item,
              ]
            : state.items.where((item) => item.id != comment.id).toList(),
        countDelta: state.countDelta - 1,
      ),
    );
  }

  /// 댓글·답글의 감정을 눌러 저장하고 목록에 반영한다.
  ///
  /// 게시물과 같은 흐름이다 — 계산은 `ReactionSummary.toggled()` 하나가 하고,
  /// 실패하면 이전 값으로 되돌린다.
  Future<Result<ReactionSummary>> toggleReaction(
    PostComment comment,
    ReactionType tapped,
  ) async {
    final previous = comment.reactions;
    _applyReaction(comment, previous.toggled(tapped));

    final result = await _reactionUseCase.toggle(
      target: ReactionTarget.comment(comment.id),
      tapped: tapped,
      current: previous,
    );
    if (isClosed) return result;

    result.when(
      ok: (next) => _applyReaction(comment, next),
      err: (_) => _applyReaction(comment, previous),
    );
    return result;
  }

  void _applyReaction(PostComment comment, ReactionSummary next) {
    final parentId = comment.parentId;

    if (parentId == null) {
      emit(
        state.copyWith(
          items: [
            for (final item in state.items)
              if (item.id == comment.id) item.withReactions(next) else item,
          ],
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        replies: {
          ...state.replies,
          parentId: [
            for (final reply in state.repliesOf(parentId))
              if (reply.id == comment.id) reply.withReactions(next) else reply,
          ],
        },
      ),
    );
  }
}
