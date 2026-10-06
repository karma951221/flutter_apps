import 'package:flutter/widgets.dart';

/// 모션 토큰 — 시간과 곡선.
///
/// 색·여백처럼 시간도 화면마다 고르면 곧 어긋난다 (CLAUDE.md 규칙 5). 그래서
/// 공통 위젯의 애니메이션 인자는 `Duration` 을 받지 않고 여기 값만 쓴다. 바꿔야
/// 하면 이 토큰을 고친다.
abstract final class AppMotion {
  /// 색·작은 전환.
  static const short = Duration(milliseconds: 150);

  /// 콘텐츠 교체.
  static const medium = Duration(milliseconds: 250);

  /// 등장.
  static const long = Duration(milliseconds: 400);

  /// 대부분의 전환. 빠르게 출발해 부드럽게 멈춘다.
  static const standard = Curves.easeOutCubic;

  /// 살짝 넘쳤다 돌아오는 탄성 — 좋아요 아이콘처럼 눌렀다는 손맛이 필요한 곳.
  static const emphasized = Curves.easeOutBack;

  /// 시스템 '애니메이션 줄이기'가 켜져 있으면 false.
  ///
  /// 켜진 사용자에게는 움직임이 불편함 그 자체일 수 있다. 위젯은 이 값이 false 면
  /// 전환 없이 최종 상태만 그린다. `MediaQuery` 가 없는 트리(일부 단위 테스트)에서도
  /// 터지지 않도록 없으면 켜진 것으로 본다.
  static bool enabled(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}
