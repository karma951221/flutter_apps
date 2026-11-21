/// 물어보기 답의 말투. [custom] 은 사용자가 적은 한 줄([ChatStyleSettings.customTone])을 쓴다.
enum ChatTone {
  standard,
  warm,
  casual,
  terse,
  custom;

  static const fallback = ChatTone.standard;

  /// 직접 입력 한 줄의 최대 글자(코드 포인트) 수.
  static const maxCustomChars = 80;

  /// system 프롬프트의 답 스타일 줄에 붙일 말투 문장. 기본이거나 직접 입력이 비면 null.
  /// 직접 입력은 줄바꿈을 빈칸으로 접고 [maxCustomChars] 까지 자른다.
  String? instruction(String customTone) => switch (this) {
    ChatTone.standard => null,
    ChatTone.warm => '말투는 다정하고 따뜻한 존댓말로.',
    ChatTone.casual => '말투는 친한 친구처럼 편한 반말로.',
    ChatTone.terse => '말투는 짧고 건조하게 — 인사 · 맞장구 · 감탄 없이 요점만.',
    ChatTone.custom => switch (normalizeCustom(customTone)) {
      '' => null,
      final line => '말투는 사용자가 정한 대로: "$line".',
    },
  };

  /// 직접 입력 한 줄을 정리한다 — 줄바꿈 · 연속 빈칸을 빈칸 하나로, 앞뒤 trim, 글자 수 상한.
  static String normalizeCustom(String raw) {
    final line = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final runes = line.runes;
    if (runes.length <= maxCustomChars) return line;
    return String.fromCharCodes(runes.take(maxCustomChars)).trim();
  }
}

/// 물어보기 답 모양 설정(전역) — 말투와 그림 만들기 도구. ChatSettings(키 · 동의)와 따로 둔다.
abstract interface class ChatStyleSettings {
  ChatTone get tone;

  /// 직접 입력 말투 한 줄. 없으면 빈 문자열. 다른 말투를 골라도 지우지 않는다.
  String get customTone;

  /// [custom] 이 있으면 직접 입력 한 줄도 함께 저장한다(정리한 값).
  Future<void> setTone(ChatTone tone, {String? custom});

  /// 그림 만들기(`generate_image`, OpenAI 연결일 때만) 도구를 줄까. 처음엔 켬.
  bool get imageGeneration;

  Future<void> setImageGeneration(bool on);
}
