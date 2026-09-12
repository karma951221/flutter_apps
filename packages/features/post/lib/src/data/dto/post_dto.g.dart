// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostDto _$PostDtoFromJson(Map<String, dynamic> json) => PostDto(
  id: json['id'] as String,
  authorId: json['author_id'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  images:
      (json['post_images'] as List<dynamic>?)
          ?.map((e) => PostImageDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  tradeResult: json['trade_result'] == null
      ? null
      : PostTradeResultDto.fromJson(
          json['trade_result'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PostDtoToJson(PostDto instance) => <String, dynamic>{
  'id': instance.id,
  'author_id': instance.authorId,
  'content': instance.content,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'post_images': instance.images,
  'trade_result': instance.tradeResult,
};
