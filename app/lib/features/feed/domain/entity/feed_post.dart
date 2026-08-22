import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_post.freezed.dart';

/// 피드에 공개된 게시물.
///
/// 작성자 정보는 후속 피드 조회 기능에서 profile domain 모델과 조합한다. 이 모델은
/// 게시물 자체의 소유자와 내용을 표현하는 데만 집중한다.
@freezed
class FeedPost with _$FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
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
}
