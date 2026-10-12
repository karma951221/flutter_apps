import 'lock_config.dart';

/// 백그라운드에서 돌아왔을 때 다시 잠글지(스펙 §7).
abstract final class RelockTimer {
  /// pausedAt 이 없으면 false. pickingMedia 면 false. now < pausedAt(시계 역행) 이면 true. now - pausedAt >= delay 면 true.
  static bool shouldLock({
    required DateTime? pausedAt,
    required DateTime now,
    required RelockDelay delay,
    required bool pickingMedia,
  }) {
    if (pausedAt == null || pickingMedia) return false;
    if (now.isBefore(pausedAt)) return true;
    return now.difference(pausedAt) >= delay.duration;
  }
}
