/// 질문 하나의 시간 흐름을 찍는다. 본문 · 키 · 도구 입력값은 찍지 않는다.
///
/// 디버그 · 프로필 빌드에서만 실제 구현이 끼워진다. 릴리스는 [NoopChatTrace].
abstract interface class ChatTrace {
  /// false 면 호출부는 data 맵도 만들지 않는다.
  bool get enabled;

  /// t0 — 새 질문.
  void begin();

  /// 표시 하나. 이름은 [ChatTraceMark].
  void mark(String label, [Map<String, Object?> data = const {}]);

  /// 요약 한 줄을 내고 비운다.
  void end();
}

/// 아무것도 찍지 않는다(릴리스 · 테스트 기본).
final class NoopChatTrace implements ChatTrace {
  const NoopChatTrace();

  @override
  bool get enabled => false;

  @override
  void begin() {}

  @override
  void mark(String label, [Map<String, Object?> data = const {}]) {}

  @override
  void end() {}
}

/// 표시 이름. 벤더 중립 — GPT 어댑터도 같은 이름을 쓴다.
abstract final class ChatTraceMark {
  // cubit · session
  static const send = 'send';
  static const key = 'key';
  static const round = 'round';

  // model
  static const req = 'req';
  static const head = 'head';
  static const first = 'first';
  static const blockStart = 'block.start';
  static const blockStop = 'block.stop';
  static const textDelta = 'textDelta';

  /// 진행 노트 하나를 냈다. data 는 `chars`(글 길이)만 — 노트 글은 찍지 않는다.
  static const progress = 'progress';
  static const msgStop = 'msgStop';

  // session
  static const toolStart = 'tool.start';
  static const toolEnd = 'tool.end';

  // cubit(프레임 뒤)
  static const firstVisible = 'firstVisible';
  static const firstGlyph = 'firstGlyph';

  // Task 5 · 7 에서 찍음
  static const userStop = 'userStop';
  static const abort = 'abort';

  static const done = 'done';
}
