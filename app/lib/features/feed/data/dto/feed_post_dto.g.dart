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
  authorNickname: json['author_nickname'] as String,
  authorAvatarUrl: json['author_avatar_url'] as String?,
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => FeedPostImageDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  reactionCounts:
      (json['reaction_counts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      {},
  myReaction: json['my_reaction'] as String?,
  commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
  tradeResult: json['trade_result'] == null
      ? null
      : FeedTradeResultDto.fromJson(
          json['trade_result'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$FeedPostDtoToJson(FeedPostDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'author_nickname': instance.authorNickname,
      'author_avatar_url': instance.authorAvatarUrl,
      'images': instance.images,
      'reaction_counts': instance.reactionCounts,
      'my_reaction': instance.myReaction,
      'comment_count': instance.commentCount,
      'trade_result': instance.tradeResult,
    };
