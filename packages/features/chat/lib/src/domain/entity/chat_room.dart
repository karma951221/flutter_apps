import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room.freezed.dart';

/// 탐색 목록에 보이는 공개방.
///
/// 아직 참여하지 않은 사람이 보는 모양이라 내 닉네임·안읽음 같은 참여자 정보가
/// 없다. 참여 중인 방은 [ChatRoomSummary] 가 따로 표현한다 — 두 화면이 보는
/// 것이 실제로 다르므로 한 타입으로 합치지 않는다.
@freezed
class ChatRoom with _$ChatRoom {
  const ChatRoom({
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
  final DateTime createdAt;
  @override
  final String? description;

  /// 나가지 않은 참여자 수. 탐색 뷰가 세어 내려준다.
  @override
  final int memberCount;
  @override
  final DateTime? lastMessageAt;
}
