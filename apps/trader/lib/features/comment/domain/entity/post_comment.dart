import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../post/domain/entity/post_author.dart';
import '../../../reaction/domain/entity/reaction_summary.dart';

part 'post_comment.freezed.dart';

/// 댓글 또는 답글 하나.
///
/// depth 는 2단 고정이다 — [parentId] 가 있으면 답글이고, 답글에는 답글을 달 수
/// 없다. 그 판정은 앱이 아니라 DB 트리거가 한다.
///
/// [content] 가 null 이면 **삭제된 댓글**이다. 답글이 남아 있는 부모는 목록에서
/// 사라지지 않고 본문만 가려진다 — 완전히 숨기면 답글이 고아가 되기 때문이다.
/// 답글은 자식을 가질 수 없으므로 삭제되면 그냥 목록에서 빠진다.
///
/// 작성자 표시는 post feature 의 `PostAuthor` 를 그대로 쓴다. 같은 사람을 두
/// 벌로 표현하지 않기 위해서다 (아키텍처 규칙 ⑥ — feature 간 참조는 domain 까지).
@freezed
class PostComment with _$PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.createdAt,
    this.parentId,
    this.content,
    this.deletedAt,
    this.replyCount = 0,
    this.reactions = const ReactionSummary(),
  });

  @override
  final String id;
  @override
  final String postId;
  @override
  final PostAuthor author;
  @override
  final DateTime createdAt;

  /// null 이면 부모 댓글, 값이 있으면 답글이다.
  @override
  final String? parentId;

  /// 삭제된 댓글은 null 이다. 뷰가 본문을 지워서 내려주므로 앱이 판단하지 않는다.
  @override
  final String? content;
  @override
  final DateTime? deletedAt;

  /// 살아 있는 답글 수. 목록 조회가 함께 내려준다 — 답글은 눌렀을 때 읽는다.
  @override
  final int replyCount;
  @override
  final ReactionSummary reactions;

  bool get isDeleted => deletedAt != null;

  bool get isReply => parentId != null;

  /// 감정만 교체한다. 낙관적 업데이트가 이 메서드를 쓴다.
  PostComment withReactions(ReactionSummary next) => PostComment(
    id: id,
    postId: postId,
    parentId: parentId,
    author: author,
    content: content,
    createdAt: createdAt,
    deletedAt: deletedAt,
    replyCount: replyCount,
    reactions: next,
  );

  /// 답글 수만 바꾼다. 답글을 달거나 지운 직후 부모를 다시 조회하지 않는다.
  PostComment withReplyCount(int count) => PostComment(
    id: id,
    postId: postId,
    parentId: parentId,
    author: author,
    content: content,
    createdAt: createdAt,
    deletedAt: deletedAt,
    replyCount: count,
    reactions: reactions,
  );

  /// 본문을 지우고 삭제 표시를 단다.
  ///
  /// 답글이 남은 부모는 목록에서 사라지지 않고 본문만 가려진다. 서버가 뷰에서
  /// 하는 일과 같은 모양을 앱이 미리 그린다 — 삭제 직후 목록을 다시 읽지 않기
  /// 위해서다. `copyWith` 로는 [content] 를 null 로 되돌릴 수 없다.
  PostComment asDeleted(DateTime at) => PostComment(
    id: id,
    postId: postId,
    parentId: parentId,
    author: author,
    createdAt: createdAt,
    deletedAt: at,
    replyCount: replyCount,
    reactions: reactions,
  );
}
