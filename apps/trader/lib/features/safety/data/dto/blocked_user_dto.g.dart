// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockedUserDto _$BlockedUserDtoFromJson(Map<String, dynamic> json) =>
    BlockedUserDto(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BlockedUserDtoToJson(BlockedUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar_url': instance.avatarUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };
