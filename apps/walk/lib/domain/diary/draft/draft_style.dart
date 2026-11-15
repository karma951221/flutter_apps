/// 초안 문체(스펙 §4 문체). 저장은 enum 이름, 모르는 값은 [fallback].
enum DraftStyle {
  /// 일기체 — 반말 '~했다'.
  diary,

  /// 존댓말 — 담백한 '~했어요'.
  polite,

  /// SNS 포스트체 — 가벼운 말투, 이모지 1~2개.
  sns,

  /// 메모체 — 짧게 끊어 '~함' · 명사형.
  memo;

  static const fallback = DraftStyle.diary;

  /// system 글에 붙는 문체 지시.
  String get instruction => switch (this) {
    DraftStyle.diary => "문체: 반말 '~했다' 로 끝나는 일기체. 해시태그와 이모지는 쓰지 않는다.",
    DraftStyle.polite => "문체: 담백한 존댓말 '~했어요'. 해시태그와 이모지는 쓰지 않는다.",
    DraftStyle.sns =>
      '문체: 가벼운 SNS 포스트 말투. 이모지는 1~2개까지, '
          '해시태그는 쓰지 않는다(태그는 따로 붙인다).',
    DraftStyle.memo => "문체: 짧게 끊어 쓰는 메모체('~함' · 명사형). 해시태그와 이모지는 쓰지 않는다.",
  };
}
