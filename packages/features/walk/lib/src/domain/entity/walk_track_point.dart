import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';

part 'walk_track_point.freezed.dart';

@freezed
class WalkTrackPoint with _$WalkTrackPoint {
  @override
  final GeoPoint point;
  @override
  final DateTime recordedAt;
  @override
  final double? accuracy;

  const WalkTrackPoint({
    required this.point,
    required this.recordedAt,
    this.accuracy,
  });
}
