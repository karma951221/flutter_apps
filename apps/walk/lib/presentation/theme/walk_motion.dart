/// 걷기 앱만의 긴 연출 시간.
///
/// 짧은 전환 · 곡선 · '애니메이션 줄이기' 판단은 design_system 의 `AppMotion` 을 쓴다
/// (`AppMotion.medium` · `AppMotion.long` · `AppMotion.standard` · `AppMotion.enabled`).
/// 여기에는 `AppMotion` 에 없는, 목표 링 · 축하처럼 느리게 보여야 하는 값만 남긴다.
abstract final class WalkMotion {
  /// 목표 링이 차오르는 시간.
  static const long = Duration(milliseconds: 900);

  /// 목표 달성 축하.
  static const celebrate = Duration(milliseconds: 1200);
}
