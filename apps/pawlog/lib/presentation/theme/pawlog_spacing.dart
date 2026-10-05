/// 간격 토큰([design.md](../../../docs/design.md) spacing). 공용 `AppSpacing`(4의 배수)과
/// 값이 달라 pawlog 화면은 이것만 쓴다.
abstract final class PawlogSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const xxl = 48.0;
}

/// 간격이 아닌 크기 토큰 — 화면에 숫자를 직접 적지 않으려고 둔다.
abstract final class PawlogSize {
  /// 화면 좌우 여백.
  static const gutter = PawlogSpacing.lg;

  /// 피드 날짜 열 너비. 본문 열과의 간격은 [PawlogSpacing.md].
  static const dateColumn = 48.0;

  /// 날짜 열 아래로 내려가는 리드줄 두께.
  static const leadLine = 1.5;

  /// 하단 고정 주 버튼 높이.
  static const primaryButton = 58.0;

  /// 주 버튼 안 로딩 표시 크기 · 선 두께.
  static const buttonSpinner = 20.0;
  static const buttonSpinnerStroke = 2.0;

  /// 경로 선 · 그 테두리(casing) 두께.
  static const routeStroke = 5.0;
  static const routeCasing = 9.0;

  /// 진행 배너의 연두 점 지름.
  static const pulseDot = 8.0;

  /// 아바타 반지름 — 줄 안(피드 · 칩) · 목록 · 편집 화면.
  static const avatarSm = 14.0;
  static const avatarMd = 20.0;
  static const avatarLg = 48.0;

  /// 여러 마리 아바타가 겹치는 폭과, 겹친 사이를 떼는 바탕색 테두리.
  static const avatarOverlap = 12.0;
  static const avatarRing = 2.0;

  /// 사진 · 경로 썸네일 비율(4:3).
  static const photoAspect = 4 / 3;

  /// 상세 화면 지도 높이.
  static const detailMap = 280.0;

  /// 저장 폼 사진 띠의 칸 크기.
  static const photoTile = 96.0;

  /// 진행 화면 시트 위 끌 손잡이.
  static const handleWidth = 36.0;
  static const handleHeight = 4.0;
}
