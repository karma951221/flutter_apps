/// 지도 바탕 모양. 동선 · 핀은 그대로고 밑에 깔리는 타일만 바뀐다.
enum MapStyle {
  /// OSM 기본 — 길 · 건물 · 가게까지 자세하다.
  standard,

  /// 옅은 색에 큰 길과 지명만(CARTO Positron).
  simple,

  /// 글자 없이 길 모양만(CARTO Positron, 라벨 없음).
  plain,

  /// 어두운 바탕(CARTO Dark Matter).
  dark;

  static const fallback = MapStyle.simple;
}
