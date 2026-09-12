/// 신고 사유. [code] 는 DB 의 reports_reason_valid CHECK 와 같은 문자열이어야 한다.
///
/// 자유 서술이 아니라 고정 목록인 이유는 운영(Studio 직접 조회)이 집계할 수 있어야
/// 하기 때문이다. 맥락은 detail 이 받는다.
enum ReportReason {
  spam('spam'),
  abuse('abuse'),
  sexual('sexual'),
  violence('violence'),
  other('other');

  const ReportReason(this.code);

  final String code;
}
