import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message.dart';

part 'chat_room_summary.freezed.dart';

/// 방의 종류. DB 의 `chat_rooms.type` 과 같은 코드를 쓴다.
enum ChatRoomType {
  open('open'),
  direct('direct');

  const ChatRoomType(this.code);

  final String code;

  /// 모르는 코드는 [open] 으로 읽는다. `my_chat_rooms` 뷰의 기본값과 같다.
  static ChatRoomType fromCode(String? code) => values.firstWhere(
    (type) => type.code == code,
    orElse: () => ChatRoomType.open,
  );
}

/// 내가 참여 중인 방 한 줄.
///
/// `my_chat_rooms` 뷰 한 행이다. 마지막 메시지 미리보기는 문장이 아니라 재료로
/// 받는다 — 시스템 메시지는 [lastMessageSystemEvent] 와 행위자 닉네임
/// ([lastMessageContent]) 을 조합해 **화면이** 문장을 만든다.
///
/// direct 방은 `title` 이 없다 — 화면에 보일 이름은 [displayTitle] 이 상대
/// 닉네임([partnerNickname])으로 채운다.
@freezed
class ChatRoomSummary with _$ChatRoomSummary {
  const ChatRoomSummary({
    required this.id,
    required this.title,
    required this.myNickname,
    required this.lastReadAt,
    this.type = ChatRoomType.open,
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

  /// open 방의 제목. direct 방은 null 이다 — [displayTitle] 을 대신 쓴다.
  @override
  final String? title;

  /// 이 방에서 쓰는 내 닉네임. 프로필 닉네임과 다를 수 있다.
  @override
  final String myNickname;
  @override
  final DateTime lastReadAt;
  @override
  final ChatRoomType type;

  /// direct 방에서 상대의 user id. open 방은 null.
  @override
  final String? partnerId;

  /// direct 방에서 상대의 닉네임. open 방은 null.
  @override
  final String? partnerNickname;

  /// direct 방에서 상대의 아바타 URL. open 방은 null.
  @override
  final String? partnerAvatarUrl;
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

  bool get isDirect => type == ChatRoomType.direct;

  /// 화면에 보일 방 이름. direct 방은 상대 닉네임, open 방은 [title].
  String? get displayTitle => isDirect ? partnerNickname : title;

  /// 안읽음만 0 으로 되돌린다. 방을 읽고 나왔을 때 목록을 다시 읽지 않는다.
  ChatRoomSummary asRead() => ChatRoomSummary(
    id: id,
    title: title,
    myNickname: myNickname,
    lastReadAt: DateTime.now(),
    type: type,
    partnerId: partnerId,
    partnerNickname: partnerNickname,
    partnerAvatarUrl: partnerAvatarUrl,
    description: description,
    memberCount: memberCount,
    unreadCount: 0,
    lastMessageAt: lastMessageAt,
    lastMessageType: lastMessageType,
    lastMessageContent: lastMessageContent,
    lastMessageSystemEvent: lastMessageSystemEvent,
  );
}
