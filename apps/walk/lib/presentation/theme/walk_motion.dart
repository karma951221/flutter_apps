import 'package:flutter/widgets.dart';

/// 걷기 앱 연출 시간 · 곡선. design_system 에 모션 토큰이 없어 앱 안에 둔다.
abstract final class WalkMotion {
  static const short = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 400);
  static const long = Duration(milliseconds: 900);
  static const celebrate = Duration(milliseconds: 1200);
  static const emphasized = Curves.easeOutCubic;

  /// 시스템 "애니메이션 제거" — 참이면 연출은 끝 상태로 바로 그리고 반복은 돌리지 않는다.
  static bool off(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
