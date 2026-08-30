/// 채팅의 입력 한계. DB 제약과 **같은 값**을 쓴다.
///
/// 서버에 갔다 와서 실패하는 것보다 여기서 막는 편이 빠르다. 최종 판정은
/// 언제나 DB 다 — 이 값이 제약과 어긋나면 화면이 통과시킨 입력이 저장에서
/// 막히므로, 마이그레이션을 고칠 때 여기도 함께 본다.
abstract final class ChatPolicy {
  /// `chat_rooms_title_len`
  static const roomTitleMaxLength = 30;

  /// `chat_rooms_desc_len`
  static const roomDescriptionMaxLength = 200;

  /// `chat_participants_nickname_len`
  static const nicknameMinLength = 2;
  static const nicknameMaxLength = 20;

  /// `chat_messages_shape` 의 text 갈래
  static const messageMaxLength = 1000;

  /// `chat_rooms_limit_range`
  static const memberLimitMin = 2;
  static const memberLimitMax = 500;
  static const memberLimitDefault = 100;

  /// 한 번에 읽는 메시지 수.
  static const messagePageSize = 30;

  /// 탐색 목록 한 페이지.
  static const roomPageSize = 20;
}
