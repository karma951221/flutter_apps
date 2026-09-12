import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room_dto.freezed.dart';
part 'chat_room_dto.g.dart';

/// `open_chat_rooms` 뷰 한 행. 탐색 화면이 읽는다.
///
/// 이 뷰는 security_invoker = off 다 — 아직 참여하지 않은 사람이 참여자 수를
/// 보려면 chat_participants 를 읽어야 하는데 그 정책이 is_room_member 이기
/// 때문이다. 내보내는 것은 집계 수 하나뿐이고 참여자 신원은 나가지 않는다.
@freezed
@JsonSerializable()
class ChatRoomDto with _$ChatRoomDto {
  const ChatRoomDto({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
    this.memberCount = 0,
    this.lastMessageAt,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  final String? description;
  @override
  @JsonKey(name: 'member_count', defaultValue: 0)
  final int memberCount;
  @override
  @JsonKey(name: 'last_message_at')
  final DateTime? lastMessageAt;

  factory ChatRoomDto.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomDtoToJson(this);
}
