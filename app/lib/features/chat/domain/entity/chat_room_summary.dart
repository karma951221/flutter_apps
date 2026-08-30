import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message.dart';

part 'chat_room_summary.freezed.dart';

/// 내가 참여 중인 방 한 줄.
///
/// `my_chat_rooms` 뷰 한 행이다. 마지막 메시지 미리보기는 문장이 아니라 재료로
/// 받는다 — 시스템 메시지는 [lastMessageSystemEvent] 와 행위자 닉네임
/// ([lastMessageContent]) 을 조합해 **화면이** 문장을 만든다.
@freezed
class ChatRoomSummary with _$ChatRoomSummary {
  const ChatRoomSummary({
    required this.id,
    required this.title,
    required this.myNickname,
    required this.lastReadAt,
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
  @override
  final String title;

  /// 이 방에서 쓰는 내 닉네임. 프로필 닉네임과 다를 수 있다.
  @override
  final String myNickname;
  @override
  final DateTime lastReadAt;
  @override
  final String? description;
  @override
  final int memberCount;

  /// 내가 읽은 시점 이후에 남이 보낸 메시지 수. 차단한 상대의 메시지는 RLS 가
  /// 이미 걸러 세지 않는다.
  @override
  final int unreadCount;
  @override
  final DateTime? lastMessageAt;
  @override
  final ChatMessageType? lastMessageType;
  @override
  final String? lastMessageContent;
  @override
  final ChatSystemEvent? lastMessageSystemEvent;

  bool get hasUnread => unreadCount > 0;

  /// 안읽음만 0 으로 되돌린다. 방을 읽고 나왔을 때 목록을 다시 읽지 않는다.
  ChatRoomSummary asRead() => ChatRoomSummary(
    id: id,
    title: title,
    myNickname: myNickname,
    lastReadAt: DateTime.now(),
    description: description,
    memberCount: memberCount,
    unreadCount: 0,
    lastMessageAt: lastMessageAt,
    lastMessageType: lastMessageType,
    lastMessageContent: lastMessageContent,
    lastMessageSystemEvent: lastMessageSystemEvent,
  );
}
