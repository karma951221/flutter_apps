// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_participant_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatParticipantDto _$ChatParticipantDtoFromJson(Map<String, dynamic> json) =>
    ChatParticipantDto(
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] == null
          ? null
          : DateTime.parse(json['left_at'] as String),
    );

Map<String, dynamic> _$ChatParticipantDtoToJson(ChatParticipantDto instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'nickname': instance.nickname,
      'joined_at': instance.joinedAt.toIso8601String(),
      'left_at': instance.leftAt?.toIso8601String(),
    };
