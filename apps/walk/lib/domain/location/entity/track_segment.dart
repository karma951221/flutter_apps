import 'package:freezed_annotation/freezed_annotation.dart';

import 'location_point.dart';
import 'record_mode.dart';

part 'track_segment.freezed.dart';

/// 이어서 그려도 되는 점들(공백 · 모드 변화로 끊긴 한 토막).
@freezed
class TrackSegment with _$TrackSegment {
  @override
  final List<LocationPoint> points;

  @override
  final RecordMode mode;

  const TrackSegment({required this.points, required this.mode});
}
