import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_dto.freezed.dart';
part 'chat_message_dto.g.dart';

/// `chat_messages` 한 행의 전송 형식.
///
/// 실시간 페이로드도 같은 모양이다 — Postgres Changes 가 주는 record 는 조인이
/// 안 된 생 행이라, 히스토리 조회를 뷰로 읽으면 두 경로의 DTO 가 갈린다.
/// 그래서 목록도 테이블을 그대로 읽는다 (계획서 "메시지 목록 조인").
///
/// 보낸 사람의 방별 닉네임은 여기 없다. 참여자 맵을 들고 있는 쪽이 붙인다.
@freezed
@JsonSerializable()
class ChatMessageDto with _$ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.roomId,
    required this.type,
    required this.createdAt,
    this.senderId,
    this.content,
    this.imagePath,
    this.systemEvent,
    this.deletedAt,
  });

  @override
  final String id;
  @override
  @JsonKey(name: 'room_id')
  final String roomId;
  @override
  final String type;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'sender_id')
  final String? senderId;
  @override
  final String? content;

  /// 비공개 버킷 안의 객체 경로다. URL 이 아니다.
  @override
  @JsonKey(name: 'image_path')
  final String? imagePath;
  @override
  @JsonKey(name: 'system_event')
  final String? systemEvent;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageDtoToJson(this);
}
