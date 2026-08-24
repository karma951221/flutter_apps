/// 신고 사유. [code] 는 DB 의 reports_reason_valid CHECK 와 같은 문자열이어야 한다.
///
/// 자유 서술이 아니라 고정 목록인 이유는 운영(Studio 직접 조회)이 집계할 수 있어야
/// 하기 때문이다. 맥락은 detail 이 받는다.
enum ReportReason {
  spam('spam', '스팸 또는 광고'),
  abuse('abuse', '욕설 또는 혐오 표현'),
  sexual('sexual', '음란물 또는 선정적인 내용'),
  violence('violence', '폭력 또는 위협'),
  other('other', '기타');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;
}
