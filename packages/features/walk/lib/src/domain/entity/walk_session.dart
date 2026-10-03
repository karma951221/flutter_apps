import 'package:freezed_annotation/freezed_annotation.dart';

import 'walk_track_point.dart';

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

  const WalkSession({
    required this.dogIds,
    required this.startedAt,
    this.endedAt,
    required this.points,
    required this.distanceMeters,
  });

  /// 엔티티가 시계를 직접 읽지 않도록 [now] 를 받는다.
  Duration elapsedAt(DateTime now) => (endedAt ?? now).difference(startedAt);
}
