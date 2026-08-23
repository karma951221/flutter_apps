import 'package:freezed_annotation/freezed_annotation.dart';

import 'post_image_dto.dart';

part 'post_dto.freezed.dart';
part 'post_dto.g.dart';

/// posts 테이블 행의 전송 형식.
@freezed
@JsonSerializable()
class PostDto with _$PostDto {
  const PostDto({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
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
  @override
  @JsonKey(name: 'post_images', defaultValue: [])
  final List<PostImageDto> images;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PostDtoToJson(this);
}
