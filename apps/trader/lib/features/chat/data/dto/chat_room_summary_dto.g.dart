// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_summary_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomSummaryDto _$ChatRoomSummaryDtoFromJson(Map<String, dynamic> json) =>
    ChatRoomSummaryDto(
      id: json['id'] as String,
      myNickname: json['my_nickname'] as String,
      lastReadAt: DateTime.parse(json['last_read_at'] as String),
      title: json['title'] as String?,
      type: json['type'] as String? ?? 'open',
      partnerId: json['partner_id'] as String?,
      partnerNickname: json['partner_nickname'] as String?,
      partnerAvatarUrl: json['partner_avatar_url'] as String?,
      description: json['description'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      lastMessageType: json['last_message_type'] as String?,
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageSystemEvent: json['last_message_system_event'] as String?,
    );

Map<String, dynamic> _$ChatRoomSummaryDtoToJson(ChatRoomSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'my_nickname': instance.myNickname,
      'last_read_at': instance.lastReadAt.toIso8601String(),
      'type': instance.type,
      'partner_id': instance.partnerId,
      'partner_nickname': instance.partnerNickname,
      'partner_avatar_url': instance.partnerAvatarUrl,
      'description': instance.description,
      'member_count': instance.memberCount,
      'unread_count': instance.unreadCount,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'last_message_type': instance.lastMessageType,
      'last_message_content': instance.lastMessageContent,
      'last_message_system_event': instance.lastMessageSystemEvent,
    };
