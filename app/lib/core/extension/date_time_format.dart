/// 목록에 찍는 날짜·시각 표기.
///
/// `post_tile` 과 `comment_tile` 이 각자 같은 자리맞춤 코드를 들고 있었다.
/// 출력 형식은 서로 다르다 — 게시물은 연도까지, 댓글은 최근 것이라 월·일부터
/// 보여준다 — 그래서 형식을 합치지 않고 자리맞춤만 한곳으로 모았다
/// (2026-08-27 리뷰).
///
/// 지금은 한국식 고정 형식이다. 언어별 표기(`intl` 의 `DateFormat`)로 옮길 때
/// 고칠 곳이 여기 하나가 되도록 두는 것이 이 확장의 목적이다
/// (docs/features/preferences/plan-language.md 의 "날짜 표기").
extension DateTimeFormat on DateTime {
  /// `2026.08.22 09:30` — 연도까지 보여준다. 게시물처럼 오래된 항목이 섞이는
  /// 목록에 쓴다.
  String get displayDateTime {
    final d = toLocal();
    return '${d.year}.${pad2(d.month)}.${pad2(d.day)} ${pad2(d.hour)}:${pad2(d.minute)}';
  }

  /// `08.22 09:30` — 연도를 생략한다. 댓글처럼 최근 항목만 보이는 목록에 쓴다.
  String get displayShortDateTime {
    final d = toLocal();
    return '${pad2(d.month)}.${pad2(d.day)} ${pad2(d.hour)}:${pad2(d.minute)}';
  }

  /// `09:30` — 날짜 없이 시각만. 대화 버블처럼 같은 날 안에서만 읽히는 자리.
  String get displayTimeOnly {
    final d = toLocal();
    return '${pad2(d.hour)}:${pad2(d.minute)}';
  }

  static String pad2(int value) => value.toString().padLeft(2, '0');
}
