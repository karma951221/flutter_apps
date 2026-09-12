import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:feature_trade/feature_trade.dart';
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

  /// go_router 상태 복원에 안전한 JSON 호환 표현.
  Map<String, Object?> toMap() => {
    'id': id,
    'author_id': authorId,
    'content': content,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'images': images.map((image) => image.toMap()).toList(),
    'trade_result': tradeResult?.toMap(),
  };

  /// [toMap]과 모양이 다르면 일부만 복원하지 않고 null을 돌려준다.
  static Post? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final authorId = raw['author_id'];
    final content = raw['content'];
    final createdAt = raw['created_at'];
    final updatedAt = raw['updated_at'];
    final rawImages = raw['images'];
    final rawTradeResult = raw['trade_result'];
    if (id is! String ||
        authorId is! String ||
        content is! String ||
        createdAt is! String ||
        updatedAt is! String ||
        rawImages is! List) {
      return null;
    }

    final parsedCreatedAt = DateTime.tryParse(createdAt);
    final parsedUpdatedAt = DateTime.tryParse(updatedAt);
    if (parsedCreatedAt == null || parsedUpdatedAt == null) return null;

    final parsedImages = <PostImage>[];
    for (final rawImage in rawImages) {
      final image = PostImage.fromMap(rawImage);
      if (image == null) return null;
      parsedImages.add(image);
    }

    final tradeResult = TradeResultSummary.fromMap(rawTradeResult);
    if (rawTradeResult != null && tradeResult == null) return null;

    return Post(
      id: id,
      authorId: authorId,
      content: content,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      images: parsedImages,
      tradeResult: tradeResult,
    );
  }
}
