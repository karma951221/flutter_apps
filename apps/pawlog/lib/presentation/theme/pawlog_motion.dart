import 'package:flutter/widgets.dart';

/// 모션 토큰. 평소엔 조용하고, 경로가 그려지는 한 장면에 몰아준다(design.md Motion).
abstract final class PawlogMotion {
  /// 누름 축소.
  static const press = Duration(milliseconds: 120);

  /// 상태 전환 · 로딩 크로스페이드.
  static const state = Duration(milliseconds: 200);

  /// 시트 올라오기.
  static const sheet = Duration(milliseconds: 300);

  /// 경로 그리기 — 유일한 연출.
  static const routeDraw = Duration(milliseconds: 1600);

  /// 진행 배너 연두 점 점멸 한 주기.
  static const pulse = Duration(milliseconds: 1600);

  /// 누른 주 버튼의 크기 비율.
  static const pressedScale = 0.97;

  /// 비활성 주 버튼의 투명도.
  static const disabledOpacity = 0.4;

  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve move = Cubic(0.4, 0, 0.2, 1);

  /// 시스템 '애니메이션 줄이기' — 참이면 끝 상태를 바로 그리고 반복은 돌리지 않는다.
  static bool off(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
