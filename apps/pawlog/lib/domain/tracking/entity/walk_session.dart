import 'package:freezed_annotation/freezed_annotation.dart';

import '../../walk/entity/walk_track_point.dart';

part 'walk_session.freezed.dart';

@freezed
class WalkSession with _$WalkSession {
  @override
  final List<String> dogIds;
  @override
  final DateTime startedAt;
  @override
  final DateTime? endedAt;
  @override
  final List<WalkTrackPoint> points;
  @override
  final double distanceMeters;

  /// 지난 멈춤 시간의 합. 진행 중인 멈춤은 [pausedAt] 이 따로 들고 있다.
  @override
  final Duration pausedDuration;

  /// 지금 멈춤 중이면 멈춘 시각, 아니면 null.
  @override
  final DateTime? pausedAt;

  const WalkSession({
    required this.dogIds,
    required this.startedAt,
    this.endedAt,
    required this.points,
    required this.distanceMeters,
    this.pausedDuration = Duration.zero,
    this.pausedAt,
  });

  bool get isPaused => pausedAt != null;

  /// 멈춘 시간을 뺀 걸은 시간. 엔티티가 시계를 직접 읽지 않도록 [now] 를 받는다.
  Duration elapsedAt(DateTime now) {
    final end = endedAt ?? now;
    final pausedAt = this.pausedAt;
    final current = pausedAt == null || end.isBefore(pausedAt)
        ? Duration.zero
        : end.difference(pausedAt);
    final value = end.difference(startedAt) - pausedDuration - current;
    return value.isNegative ? Duration.zero : value;
  }
}
