/// 지도 종류. 동선 · 핀은 그대로고 밑에 깔리는 타일만 바뀐다. 모두 API 키 없이 받는다.
///
/// 단순 · 기본 · 어둡게는 OSM 기본 타일 하나에 앱이 색 필터를 씌운다. 지형은 OpenTopoMap,
/// 위성은 Esri World Imagery. CARTO basemap 은 키 없이는 "API KEY REQUIRED" 타일만 준다(2026-11-14).
/// 시트에는 이 순서로 보인다.
enum MapStyle {
  /// OSM 에 색을 빼고 옅게 — 동선이 바탕보다 눈에 띈다. 기본값.
  simple,

  /// OSM 기본 — 길 · 건물 · 가게까지 자세하다.
  standard,

  /// 등고선 · 산 높이(OpenTopoMap). 등산 · 여행용.
  terrain,

  /// 위성 사진(Esri World Imagery).
  satellite,

  /// OSM 을 회색으로 뒤집은 어두운 지도.
  dark;

  static const fallback = MapStyle.simple;
}
