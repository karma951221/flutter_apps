import 'package:freezed_annotation/freezed_annotation.dart';

import 'location_point.dart';
import 'record_interval.dart';
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

/// 굵게(자세히) 그릴 토막인가 — 고정 주기([RecordMode.dense]) 기록이고 점 사이 간격의 중앙값이
/// [RecordInterval.detailedMaxSeconds] 이하. 점에는 주기가 없어 실제 간격으로 본다 — 예전 5초
/// 기록도 그대로 굵고, 1분 주기는 평소처럼 얇다. 점이 둘 이하면 간격을 믿기 어려워 모드만 본다.
bool isDetailedSegment(TrackSegment segment) {
  if (segment.mode != RecordMode.dense) return false;
  final points = segment.points;
  if (points.length < 3) return true;
  final gaps = [
    for (var i = 1; i < points.length; i++)
      points[i].recordedAt.difference(points[i - 1].recordedAt).inMilliseconds,
  ]..sort();
  return gaps[gaps.length ~/ 2] <= RecordInterval.detailedMaxSeconds * 1000;
}
