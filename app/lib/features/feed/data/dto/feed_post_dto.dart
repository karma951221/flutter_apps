import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_post_dto.freezed.dart';
part 'feed_post_dto.g.dart';

/// feed_posts 테이블 행의 전송 형식.
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
