/// 오래된 대화 자동 삭제(D10). 위키 · 사용량과 무관.
enum ChatRetention {
  never(null),
  day30(Duration(days: 30)),
  day90(Duration(days: 90));

  const ChatRetention(this.period);

  /// null 이면 지우지 않는다.
  final Duration? period;

  static const fallback = ChatRetention.never;
}

/// 대화 · 위키 설정. 2단계가 wikiIndexSize 를 더한다. ChatSettings(키 · 동의)와 따로 둔다.
abstract interface class ChatHistorySettings {
  ChatRetention get retention;

  Future<void> setRetention(ChatRetention value);
}
