/// ODsay 지하철 노선 코드 → 서울 실시간 도착 API 의 `subwayId`. 매핑이 없으면 null.
/// 실제 응답으로 재확인이 필요하다(Task 9).
int? seoulSubwayIdFor(int odsayLaneCode) {
  if (odsayLaneCode >= 1 && odsayLaneCode <= 9) return 1000 + odsayLaneCode;
  return switch (odsayLaneCode) {
    109 => 1077, // 신분당
    116 => 1075, // 수인분당
    104 => 1063, // 경의중앙
    101 => 1065, // 공항철도
    _ => null,
  };
}

/// 역 이름 끝의 `역` 을 떼고 다듬는다.
String normalizeStationName(String name) {
  final trimmed = name.trim();
  return trimmed.endsWith('역') && trimmed.length > 1
      ? trimmed.substring(0, trimmed.length - 1).trim()
      : trimmed;
}
