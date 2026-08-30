import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

/// 메시지의 종류. DB 의 `chat_messages.type` 과 같은 코드를 쓴다.
enum ChatMessageType {
  text('text'),
  image('image'),
  system('system');

  const ChatMessageType(this.code);

  final String code;

  /// 모르는 코드는 [text] 로 읽는다. 서버에 종류가 늘어난 버전이 먼저 나가도
  /// 앱이 죽지 않는다.
  static ChatMessageType fromCode(String? code) => values.firstWhere(
    (type) => type.code == code,
    orElse: () => ChatMessageType.text,
  );
}

/// 시스템 메시지가 알리는 사건.
///
/// DB 는 문장이 아니라 이 키를 저장하고, 문장은 앱의 ARB 가 만든다 — DB 에
/// 한국어를 넣으면 다국어에 갚을 빚이 하나 더 생긴다 (계획서).
enum ChatSystemEvent {
  join('join'),
  leave('leave');

  const ChatSystemEvent(this.code);

  final String code;

  static ChatSystemEvent? fromCode(String? code) {
    if (code == null) return null;
    for (final event in values) {
      if (event.code == code) return event;
    }
    return null;
  }
}

/// 보낸 메시지가 서버에 닿았는지.
///
/// 서버에서 읽어온 메시지는 언제나 [sent] 다. [pending] 과 [failed] 는 낙관적
/// 전송이 만들어내는 화면상의 상태다 — 버블을 즉시 띄우고 결과에 따라 확정하거나
/// 재전송 버튼을 남긴다.
enum ChatMessageDelivery { sent, pending, failed }

/// 방에 오간 메시지 하나.
///
/// [senderNickname] 은 방별 닉네임이라 프로필이 아니라 참여자 행에서 온다.
/// 목록 조회는 조인 뷰를 쓰지 않으므로(계획서 "메시지 목록 조인") 이 값은
/// cubit/bloc 이 참여자 맵을 보고 채운다. 실시간 페이로드도 같은 방법으로
/// 채워지기 때문에 두 경로의 모양이 같아진다.
@freezed
class ChatMessage with _$ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.type,
    required this.createdAt,
    this.senderId,
    this.content,
    this.imagePath,
    this.systemEvent,
    this.senderNickname,
    this.delivery = ChatMessageDelivery.sent,
  });

  @override
  final String id;
  @override
  final String roomId;
  @override
  final ChatMessageType type;
  @override
  final DateTime createdAt;

  /// 시스템 메시지는 보낸 사람이 없다.
  @override
  final String? senderId;

  /// `text` 는 본문, `system` 은 행위자 닉네임 스냅샷이다.
  @override
  final String? content;

  /// `chat-images` 버킷 안의 객체 경로. 비공개 버킷이라 URL 이 아니다 —
  /// 화면에 띄울 때 서명 URL 을 만든다.
  @override
  final String? imagePath;
  @override
  final ChatSystemEvent? systemEvent;
  @override
  final String? senderNickname;
  @override
  final ChatMessageDelivery delivery;

  bool get isSystem => type == ChatMessageType.system;

  bool get isPending => delivery == ChatMessageDelivery.pending;

  bool get isFailed => delivery == ChatMessageDelivery.failed;

  bool isMine(String userId) => senderId == userId;

  ChatMessage withDelivery(ChatMessageDelivery next) => ChatMessage(
    id: id,
    roomId: roomId,
    type: type,
    createdAt: createdAt,
    senderId: senderId,
    content: content,
    imagePath: imagePath,
    systemEvent: systemEvent,
    senderNickname: senderNickname,
    delivery: next,
  );

  /// 방별 닉네임을 붙인다. 목록과 실시간 두 경로가 모두 이걸 지난다.
  ChatMessage withSenderNickname(String? nickname) => ChatMessage(
    id: id,
    roomId: roomId,
    type: type,
    createdAt: createdAt,
    senderId: senderId,
    content: content,
    imagePath: imagePath,
    systemEvent: systemEvent,
    senderNickname: nickname,
    delivery: delivery,
  );
}
