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

/// 위키 색인 상한(D14). maxNotes 가 null 이면 개수 제한 없음.
enum WikiIndexSize {
  small(50, 2000),
  standard(150, 6000),
  large(300, 12000),
  all(null, 30000);

  const WikiIndexSize(this.maxNotes, this.maxChars);

  final int? maxNotes;
  final int maxChars;

  static const fallback = WikiIndexSize.standard;
}

/// 대화 · 위키 설정. ChatSettings(키 · 동의)와 따로 둔다.
abstract interface class ChatHistorySettings {
  ChatRetention get retention;

  Future<void> setRetention(ChatRetention value);

  WikiIndexSize get wikiIndexSize;

  Future<void> setWikiIndexSize(WikiIndexSize value);
}
