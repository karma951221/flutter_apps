import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room_summary_dto.freezed.dart';
part 'chat_room_summary_dto.g.dart';

/// `my_chat_rooms` 뷰 한 행. 채팅 탭의 목록이 읽는다.
///
/// 이 뷰는 security_invoker = on 이라 호출자의 RLS 가 그대로 걸린다 —
/// 차단한 상대의 메시지는 [unreadCount] 에서도 미리보기에서도 빠진다.
@freezed
@JsonSerializable()
class ChatRoomSummaryDto with _$ChatRoomSummaryDto {
  const ChatRoomSummaryDto({
    required this.id,
    required this.myNickname,
    required this.lastReadAt,
    this.title,
    this.type = 'open',
    this.partnerId,
    this.partnerNickname,
    this.partnerAvatarUrl,
    this.description,
    this.memberCount = 0,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.lastMessageType,
    this.lastMessageContent,
    this.lastMessageSystemEvent,
  });

  @override
  final String id;

  /// open 방의 제목. direct 방은 null.
  @override
  final String? title;
  @override
  @JsonKey(name: 'my_nickname')
  final String myNickname;
  @override
  @JsonKey(name: 'last_read_at')
  final DateTime lastReadAt;
  @override
  @JsonKey(name: 'type', defaultValue: 'open')
  final String type;
  @override
  @JsonKey(name: 'partner_id')
  final String? partnerId;
  @override
  @JsonKey(name: 'partner_nickname')
  final String? partnerNickname;
  @override
  @JsonKey(name: 'partner_avatar_url')
  final String? partnerAvatarUrl;
  @override
  final String? description;
  @override
  @JsonKey(name: 'member_count', defaultValue: 0)
  final int memberCount;
  @override
  @JsonKey(name: 'unread_count', defaultValue: 0)
  final int unreadCount;
  @override
  @JsonKey(name: 'last_message_at')
  final DateTime? lastMessageAt;
  @override
  @JsonKey(name: 'last_message_type')
  final String? lastMessageType;
  @override
  @JsonKey(name: 'last_message_content')
  final String? lastMessageContent;
  @override
  @JsonKey(name: 'last_message_system_event')
  final String? lastMessageSystemEvent;

  factory ChatRoomSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomSummaryDtoToJson(this);
}
