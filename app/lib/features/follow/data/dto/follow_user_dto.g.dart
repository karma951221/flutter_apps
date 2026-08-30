// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowUserDto _$FollowUserDtoFromJson(Map<String, dynamic> json) =>
    FollowUserDto(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FollowUserDtoToJson(FollowUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar_url': instance.avatarUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };
