import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/entity/track_segment.dart';

TrackSegment _segment(RecordMode mode, int count, int gapSec) => TrackSegment(
  mode: mode,
  points: [
    for (var i = 0; i < count; i++)
      LocationPoint(
        recordedAt: DateTime.utc(
          2026,
          11,
          19,
          9,
        ).add(Duration(seconds: i * gapSec)),
        lat: 37.5 + i * 0.001,
        lng: 127,
        mode: mode,
      ),
  ],
);

void main() {
  test('평소 모드 토막은 굵게 그리지 않는다', () {
    expect(isDetailedSegment(_segment(RecordMode.normal, 10, 5)), isFalse);
  });

  test('예전 5초 · 10초 · 30초 고정 주기는 굵게', () {
    expect(isDetailedSegment(_segment(RecordMode.dense, 10, 5)), isTrue);
    expect(isDetailedSegment(_segment(RecordMode.dense, 10, 10)), isTrue);
    expect(isDetailedSegment(_segment(RecordMode.dense, 10, 30)), isTrue);
  });

  test('1분 고정 주기는 얇게', () {
    expect(isDetailedSegment(_segment(RecordMode.dense, 10, 60)), isFalse);
  });

  test('간격은 중앙값으로 본다 — 멈춰 있던 긴 틈 하나로 바뀌지 않는다', () {
    final s = _segment(RecordMode.dense, 10, 5);
    final points = [
      ...s.points,
      s.points.last.copyWith(
        recordedAt: s.points.last.recordedAt.add(const Duration(minutes: 20)),
      ),
    ];
    expect(
      isDetailedSegment(TrackSegment(points: points, mode: RecordMode.dense)),
      isTrue,
    );
  });

  test('점이 둘 이하면 모드만 본다', () {
    expect(isDetailedSegment(_segment(RecordMode.dense, 2, 300)), isTrue);
  });
}
