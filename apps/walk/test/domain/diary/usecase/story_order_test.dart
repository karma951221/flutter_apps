import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/usecase/story_order.dart';

Story _story(
  String id, {
  required DateTime createdAt,
  DateTime? lastPostedAt,
  DateTime? endedAt,
}) => Story(
  id: id,
  title: id,
  status: endedAt == null ? StoryStatus.open : StoryStatus.closed,
  startedAt: DateTime(2026, 1, 1),
  endedAt: endedAt,
  lastPostedAt: lastPostedAt,
  createdAt: createdAt,
);

void main() {
  test('open 은 lastPostedAt 내림차순, 없으면 createdAt 으로 비교한다', () {
    final split = StoryOrder.split([
      _story(
        Story.dailyId,
        createdAt: DateTime(2026, 1, 1),
        lastPostedAt: DateTime(2026, 10, 5),
      ),
      _story(
        'jeju',
        createdAt: DateTime(2026, 9, 1),
        lastPostedAt: DateTime(2026, 10, 9),
      ),
      // 기록이 없지만 최근에 만들었다 → createdAt 10/7 로 비교.
      _story('trip', createdAt: DateTime(2026, 10, 7)),
    ]);

    expect(split.open.map((s) => s.id), ['jeju', 'trip', Story.dailyId]);
    expect(split.archived, isEmpty);
  });

  test('open 에서 같은 시각이면 최근에 만든 것이 앞', () {
    final at = DateTime(2026, 10, 5);
    final split = StoryOrder.split([
      _story('old', createdAt: DateTime(2026, 1, 1), lastPostedAt: at),
      _story('new', createdAt: DateTime(2026, 2, 1), lastPostedAt: at),
    ]);

    expect(split.open.map((s) => s.id), ['new', 'old']);
  });

  test('closed 는 보관함으로, endedAt 내림차순', () {
    final split = StoryOrder.split([
      _story(
        'a',
        createdAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 3, 1),
        lastPostedAt: DateTime(2026, 10, 1),
      ),
      _story(
        'b',
        createdAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 5, 1),
      ),
      _story(Story.dailyId, createdAt: DateTime(2026, 1, 1)),
    ]);

    expect(split.open.map((s) => s.id), [Story.dailyId]);
    expect(split.archived.map((s) => s.id), ['b', 'a']);
  });
}
