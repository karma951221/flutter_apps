// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageDto _$ChatMessageDtoFromJson(Map<String, dynamic> json) =>
    ChatMessageDto(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderId: json['sender_id'] as String?,
      content: json['content'] as String?,
      imagePath: json['image_path'] as String?,
      systemEvent: json['system_event'] as String?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$ChatMessageDtoToJson(ChatMessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'room_id': instance.roomId,
      'type': instance.type,
      'created_at': instance.createdAt.toIso8601String(),
      'sender_id': instance.senderId,
      'content': instance.content,
      'image_path': instance.imagePath,
      'system_event': instance.systemEvent,
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
