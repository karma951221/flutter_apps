import 'package:freezed_annotation/freezed_annotation.dart';

import 'stay.dart';
import 'track_segment.dart';

part 'day_track.freezed.dart';

/// 한 기간의 이동선 구간들과 머문 곳들.
@freezed
class DayTrack with _$DayTrack {
  @override
  final List<TrackSegment> segments;

  @override
  final List<Stay> stays;

  const DayTrack({required this.segments, required this.stays});

  bool get isEmpty => segments.isEmpty && stays.isEmpty;
}
