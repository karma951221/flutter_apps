import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../trade/domain/entity/trade_result_summary.dart';
import 'post_image.dart';

part 'post.freezed.dart';

/// 사용자가 작성한 게시물.
///
/// 작성자 프로필과 반응·댓글 수는 피드가 조회 시점에 조합한다. 이 모델은 게시물
/// 자체의 소유자와 내용만 표현한다.
@freezed
class Post with _$Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.tradeResult,
  });

  @override
  final String id;
  @override
  final String authorId;
  @override
  final String content;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final List<PostImage> images;

  /// 게시물에 붙은 끝난 판의 결과 요약. 판을 붙이지 않았으면 null 이다.
  ///
  /// 판은 게시물을 만들 때 한 번 붙고 이후 바뀌지 않는다(docs/schema.md §5 —
  /// `trade_session_id` 에는 UPDATE GRANT 가 없다).
  @override
  final TradeResultSummary? tradeResult;
}
