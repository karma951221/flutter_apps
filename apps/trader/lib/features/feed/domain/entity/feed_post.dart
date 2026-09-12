import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:feature_post/feature_post.dart';
import 'package:feature_reaction/feature_reaction.dart';

part 'feed_post.freezed.dart';

/// 피드 목록의 한 항목 — 게시물과 그 작성자.
///
/// `Post` 에 닉네임을 넣지 않고 감싸는 이유는 `Post` 문서 주석이 정한 그대로다.
/// `Post` 는 게시물 자체(소유자 id · 내용)만 표현하고, 작성자 프로필과 반응 수 ·
/// 댓글 수는 피드가 조회 시점에 조합한다. 게시물 작성·수정
/// 화면은 작성자 프로필이 필요 없는데, `Post` 에 필드를 더하면 그쪽까지 값을
/// 채워야 한다.
///
/// 그래서 게시물을 고쳐도 [author] 는 그대로 둘 수 있다 — [withPost] 참고.
@freezed
class FeedPost with _$FeedPost {
  const FeedPost({
    required this.post,
    required this.author,
    this.reactions = const ReactionSummary(),
    this.commentCount = 0,
  });

  @override
  final Post post;
  @override
  final PostAuthor author;

  /// 감정 집계와 내 반응. 목록 뷰가 항목과 함께 내려준다 — 항목마다 다시
  /// 조회하면 그게 뷰로 없애려던 N+1 이다.
  @override
  final ReactionSummary reactions;

  /// 살아 있는 댓글과 답글의 합.
  @override
  final int commentCount;

  /// 목록에서 항목을 찾을 때 쓰는 식별자. 게시물 id 다.
  String get id => post.id;

  /// 내용만 바뀐 게시물로 교체한다. 작성자·반응·댓글 수는 수정으로 바뀌지 않는다.
  FeedPost withPost(Post updated) => FeedPost(
    post: updated,
    author: author,
    reactions: reactions,
    commentCount: commentCount,
  );

  /// 반응만 교체한다. 낙관적 업데이트가 이 메서드를 쓴다.
  FeedPost withReactions(ReactionSummary next) => FeedPost(
    post: post,
    author: author,
    reactions: next,
    commentCount: commentCount,
  );
}
