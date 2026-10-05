import 'package:l10n/l10n.dart';

/// 산책 거리 · 시간 표기. 위젯 없이 로케일 문자열만 받는 순수 함수다.
abstract final class WalkFormat {
  /// 1 km 미만은 `850 m`, 그 외는 소수 1자리 `1.2 km`.
  static String distance(AppLocalizations l10n, double meters) {
    final rounded = meters.round();
    if (rounded < 1000) return l10n.walkDistanceMeters(rounded);
    return l10n.walkDistanceKm((meters / 1000).toStringAsFixed(1));
  }

  /// 피드 · 상세용 요약 시간. 1분 미만은 `1분 미만`(`0분` 은 기록이 없는 것처럼 읽힌다),
  /// 1시간 미만은 `23분`, 그 외는 `1시간 5분` — 분이 0 이면 `1시간`. 초는 버린다.
  static String duration(AppLocalizations l10n, Duration d) {
    if (d.inMinutes < 1) return l10n.walkDurationUnderMinute;
    if (d.inHours < 1) return l10n.walkDurationMinutes(d.inMinutes);
    final minutes = d.inMinutes.remainder(60);
    if (minutes == 0) return l10n.walkDurationHours(d.inHours);
    return l10n.walkDurationHoursMinutes(d.inHours, minutes);
  }

  /// 진행 화면의 초 단위 시계. 1시간 미만 `mm:ss`, 그 외 `h:mm:ss`. 로케일 무관.
  static String clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final seconds = two(d.inSeconds.remainder(60));
    final minutes = d.inMinutes.remainder(60);
    if (d.inHours < 1) return '${two(minutes)}:$seconds';
    return '${d.inHours}:${two(minutes)}:$seconds';
  }
}
