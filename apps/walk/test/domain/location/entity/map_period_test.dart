import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/location/entity/map_period.dart';

Story _story({DateTime? endedAt}) => Story(
  id: 's1',
  title: '여행',
  status: endedAt == null ? StoryStatus.open : StoryStatus.closed,
  startedAt: DateTime(2026, 11, 1, 10),
  endedAt: endedAt,
  createdAt: DateTime(2026, 11, 1, 10),
);

void main() {
  final now = DateTime(2026, 11, 8, 12);

  test('MapPeriod.day bounds use local midnight', () {
    final b = MapPeriod.day(DateTime(2026, 11, 8, 15)).bounds(now);
    expect(b.from, DateTime(2026, 11, 8));
    expect(b.to, DateTime(2026, 11, 8, 23, 59, 59, 999));
  });

  test('MapPeriod.month covers the whole month', () {
    final b = const MapPeriod.month(2026, 2).bounds(now);
    expect(b.from, DateTime(2026, 2, 1));
    expect(b.to, DateTime(2026, 2, 28, 23, 59, 59, 999));
  });

  test('open story ends at now', () {
    final b = MapPeriod.story(_story()).bounds(now);
    expect(b.from, DateTime(2026, 11, 1, 10));
    expect(b.to, now);
  });

  test('closed story ends at endedAt', () {
    final end = DateTime(2026, 11, 5, 18);
    expect(MapPeriod.story(_story(endedAt: end)).bounds(now).to, end);
  });
}
