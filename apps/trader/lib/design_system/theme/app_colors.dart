import 'package:flutter/material.dart';

/// 색상 토큰.
///
/// 위젯에서 Colors.* 를 직접 쓰지 않는다. 전부 여기를 거친다.
abstract final class AppColors {
  static const seed = Color(0xFF4C6EF5);

  static const like = Color(0xFF2F9E44);
  static const dislike = Color(0xFFE03131);

  /// 상승 빨강 · 하락 파랑 — ko/ja 시장 관행. [like]/[dislike] 와 별개 토큰인
  /// 이유는 의미가 다르기 때문(호감/비호감이 아니라 시세의 방향이다).
  static const candleUp = Color(0xFFE03131);
  static const candleDown = Color(0xFF1C7ED6);
}
