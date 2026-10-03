import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 걷기 앱 톤 — 청록빛 초록. 다른 앱과 공유하지 않으므로 design_system 이 아니라 여기 둔다.
abstract final class WalkTheme {
  static const seed = Color(0xFF1D9E75);

  static ThemeData light() => AppTheme.light(seedColor: seed);
  static ThemeData dark() => AppTheme.dark(seedColor: seed);
}
