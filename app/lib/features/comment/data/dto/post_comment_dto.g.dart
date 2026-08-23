// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostCommentDto _$PostCommentDtoFromJson(Map<String, dynamic> json) =>
    PostCommentDto(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      authorNickname: json['author_nickname'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      parentId: json['parent_id'] as String?,
      content: json['content'] as String?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      authorAvatarUrl: json['author_avatar_url'] as String?,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      reactionCounts:
          (json['reaction_counts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          {},
      myReaction: json['my_reaction'] as String?,
    );

Map<String, dynamic> _$PostCommentDtoToJson(PostCommentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'post_id': instance.postId,
      'parent_id': instance.parentId,
      'author_id': instance.authorId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'author_nickname': instance.authorNickname,
      'author_avatar_url': instance.authorAvatarUrl,
      'reply_count': instance.replyCount,
      'reaction_counts': instance.reactionCounts,
      'my_reaction': instance.myReaction,
    };
