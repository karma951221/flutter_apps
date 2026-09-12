// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_image_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostImageDto _$PostImageDtoFromJson(Map<String, dynamic> json) => PostImageDto(
  id: json['id'] as String,
  url: json['url'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  sortOrder: (json['sort_order'] as num).toInt(),
);

Map<String, dynamic> _$PostImageDtoToJson(PostImageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'sort_order': instance.sortOrder,
    };
