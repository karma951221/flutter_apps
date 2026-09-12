/// 신고 domain 정책.
///
/// DB 의 reports_detail_length CHECK 와 같은 값을 쓴다. 앱 검증은 UX 이고 최종
/// 판정은 DB 가 하지만, 두 값이 어긋나면 사용자에게 날것의 DB 오류가 간다.
abstract final class ReportPolicy {
  /// 상세 설명 최대 길이. docs/schema.md 의 reports_detail_length 와 같아야 한다.
  static const maxDetailLength = 500;

  /// 빈 입력을 null 로 만든다.
  ///
  /// DB 는 빈 문자열을 거부한다 — 저장 가능한 상태를 "null 이거나 내용이 있음"
  /// 하나로 줄이기 위해서다. 앱이 짝을 맞춰 정규화하므로 정상 경로에서 그
  /// 제약에 걸릴 일은 없다.
  static String? normalizeDetail(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
