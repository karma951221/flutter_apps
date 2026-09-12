import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/post_comment.dart';

part 'comment_state.freezed.dart';

/// 댓글 화면의 상태.
///
/// 부모 댓글은 [items] 에, 답글은 부모 id 로 나눈 [replies] 에 둔다. 답글을
/// 부모 안에 중첩해 담지 않는 이유는 조회가 애초에 분리돼 있기 때문이다 —
/// 답글은 부모를 눌렀을 때 읽는다 (docs/features/comment/plan.md).
@freezed
class CommentState with _$CommentState {
  const CommentState({
    this.status = CommentStatus.loading,
    this.items = const [],
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
    this.replies = const {},
    this.expandedParentIds = const {},
    this.loadingParentIds = const {},
    this.replyCursors = const {},
    this.isSubmitting = false,
    this.countDelta = 0,
  });

  @override
  final CommentStatus status;

  /// 부모 댓글. 오래된 순이다.
  @override
  final List<PostComment> items;
  @override
  final bool isLoadingMore;

  /// 다음 페이지 커서. null 이면 마지막까지 읽었다는 뜻이다.
  @override
  final String? nextCursor;
  @override
  final Failure? failure;

  /// 부모 id → 읽어둔 답글.
  @override
  final Map<String, List<PostComment>> replies;

  /// 펼쳐 놓은 부모 id.
  @override
  final Set<String> expandedParentIds;

  /// 답글을 읽는 중인 부모 id.
  @override
  final Set<String> loadingParentIds;

  /// 부모 id → 답글의 다음 커서.
  @override
  final Map<String, String?> replyCursors;

  /// 작성·삭제 요청이 진행 중인지.
  @override
  final bool isSubmitting;

  /// 이 화면에서 늘거나 준 댓글 수.
  ///
  /// 피드로 돌아갈 때 목록을 다시 읽지 않고 해당 항목의 수만 고치기 위한
  /// 값이다. 화면이 들어올 때의 수에 이 값을 더해 돌려준다.
  @override
  final int countDelta;

  bool get canLoadMore => nextCursor != null;

  List<PostComment> repliesOf(String parentId) =>
      replies[parentId] ?? const [];

  bool isExpanded(String parentId) => expandedParentIds.contains(parentId);

  bool isLoadingReplies(String parentId) =>
      loadingParentIds.contains(parentId);

  bool canLoadMoreReplies(String parentId) => replyCursors[parentId] != null;
}

enum CommentStatus { loading, loaded, failure }
