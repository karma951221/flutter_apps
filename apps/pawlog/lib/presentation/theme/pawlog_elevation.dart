import 'package:flutter/painting.dart';

/// 그림자는 두 곳에만 — 하단 주 버튼과 지도 위 시트. 나머지는 `rule` 1px 로 나눈다.
abstract final class PawlogShadows {
  /// 하단 주 버튼 — 아래로 6, 블러 16.
  static List<BoxShadow> primaryButton(Color color) => [
    BoxShadow(color: color, offset: const Offset(0, 6), blurRadius: 16),
  ];

  /// 지도 위 시트 — 위로 6, 블러 18.
  static List<BoxShadow> sheet(Color color) => [
    BoxShadow(color: color, offset: const Offset(0, -6), blurRadius: 18),
  ];
}
