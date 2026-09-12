import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_post_image_dto.freezed.dart';
part 'feed_post_image_dto.g.dart';

@freezed
@JsonSerializable()
class FeedPostImageDto with _$FeedPostImageDto {
  const FeedPostImageDto({
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

  factory FeedPostImageDto.fromJson(Map<String, dynamic> json) =>
      _$FeedPostImageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$FeedPostImageDtoToJson(this);
}
