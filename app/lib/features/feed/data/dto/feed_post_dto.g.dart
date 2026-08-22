// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_post_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedPostDto _$FeedPostDtoFromJson(Map<String, dynamic> json) => FeedPostDto(
  id: json['id'] as String,
  authorId: json['author_id'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$FeedPostDtoToJson(FeedPostDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
