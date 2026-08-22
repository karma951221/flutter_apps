import 'package:freezed_annotation/freezed_annotation.dart';

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
