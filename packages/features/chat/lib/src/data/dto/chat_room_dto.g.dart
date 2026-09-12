// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomDto _$ChatRoomDtoFromJson(Map<String, dynamic> json) => ChatRoomDto(
  id: json['id'] as String,
  title: json['title'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  description: json['description'] as String?,
  memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
  lastMessageAt: json['last_message_at'] == null
      ? null
      : DateTime.parse(json['last_message_at'] as String),
);

Map<String, dynamic> _$ChatRoomDtoToJson(ChatRoomDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'created_at': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'member_count': instance.memberCount,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
    };
