/// 지도 바탕 모양. 동선 · 핀은 그대로고 밑에 깔리는 타일만 바뀐다.
enum MapStyle {
  /// OSM 기본 — 길 · 건물 · 가게까지 자세하다.
  standard,

  /// 옅은 회색에 큰 길과 지명만(Esri 어두운 회색 캔버스를 반전).
  simple,

  /// 글자 없이 길 모양만(단순에서 지명 레이어를 뺌).
  plain,

  /// 어두운 바탕(Esri 어두운 회색 캔버스 그대로).
  dark;

  static const fallback = MapStyle.simple;
}
