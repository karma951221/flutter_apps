import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_post_dto.freezed.dart';
part 'feed_post_dto.g.dart';

/// 피드가 조회하는 posts 행의 전송 형식.
///
/// post feature 의 `PostDto` 와 지금은 모양이 같지만 소유자가 다르다. 피드는
/// 앞으로 작성자 프로필·반응 수·댓글 수를 조인해 함께 받게 되고, 게시물 단건
/// 조회는 그렇지 않다. feature 의 data 계층은 서로 참조하지 않는다
/// (아키텍처 규칙 ⑤·⑥).
@freezed
@JsonSerializable()
class FeedPostDto with _$FeedPostDto {
  const FeedPostDto({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;
  @override
  final String content;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  factory FeedPostDto.fromJson(Map<String, dynamic> json) =>
      _$FeedPostDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FeedPostDtoToJson(this);
}
