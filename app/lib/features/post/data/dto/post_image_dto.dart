import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_image_dto.freezed.dart';
part 'post_image_dto.g.dart';

@freezed
@JsonSerializable()
class PostImageDto with _$PostImageDto {
  const PostImageDto({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    required this.sortOrder,
  });

  @override
  final String id;
  @override
  final String url;
  @override
  final int width;
  @override
  final int height;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  factory PostImageDto.fromJson(Map<String, dynamic> json) =>
      _$PostImageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PostImageDtoToJson(this);
}
