import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/usecase/story_suggestion.dart';

Story _story(
  String id, {
  DateTime? createdAt,
  DateTime? lastPostedAt,
  DateTime? startedAt,
  DateTime? endedAt,
  bool closed = false,
}) => Story(
  id: id,
  title: id,
  status: closed ? StoryStatus.closed : StoryStatus.open,
  startedAt: startedAt ?? DateTime(2026, 1, 1),
  endedAt: endedAt,
  lastPostedAt: lastPostedAt,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
);

final _daily = _story(Story.dailyId, lastPostedAt: DateTime(2026, 10, 5));

void main() {
  group('defaultFor — 작성 기본 스토리', () {
    test('open 중 lastPostedAt 이 가장 최근인 스토리', () {
      final stories = [
        _daily,
        _story('jeju', lastPostedAt: DateTime(2026, 10, 9)),
        _story('busan', lastPostedAt: DateTime(2026, 10, 7)),
      ];

      expect(StorySuggestion.defaultFor(stories), 'jeju');
    });

    test('닫힌 스토리는 더 최근에 썼어도 제외한다', () {
      final stories = [
        _daily,
        _story(
          'jeju',
          lastPostedAt: DateTime(2026, 10, 9),
          endedAt: DateTime(2026, 10, 9),
          closed: true,
        ),
      ];

      expect(StorySuggestion.defaultFor(stories), Story.dailyId);
    });

    test('기록이 없으면 "일상"', () {
      expect(
        StorySuggestion.defaultFor([_story(Story.dailyId)]),
        Story.dailyId,
      );
      expect(StorySuggestion.defaultFor(const []), Story.dailyId);
    });

    test('lastPostedAt 이 같으면 최근에 만든 스토리', () {
      final at = DateTime(2026, 10, 9);
      final stories = [
        _daily,
        _story('older', createdAt: DateTime(2026, 9, 1), lastPostedAt: at),
        _story('newer', createdAt: DateTime(2026, 9, 2), lastPostedAt: at),
      ];

      expect(StorySuggestion.defaultFor(stories), 'newer');
    });
  });

  group('forTime — 시각을 바꿨을 때 제안', () {
    final at = DateTime(2026, 8, 15, 12);

    test('그 시각이 기간에 드는 open 스토리', () {
      final stories = [
        _daily,
        _story(
          'jeju',
          startedAt: DateTime(2026, 8, 14),
          endedAt: DateTime(2026, 8, 16),
        ),
        _story(
          'busan',
          startedAt: DateTime(2026, 9, 1),
          lastPostedAt: DateTime(2026, 10, 9),
        ),
      ];

      expect(StorySuggestion.forTime(stories, at), 'jeju');
    });

    test('여럿이면 lastPostedAt 이 가장 최근인 것', () {
      final stories = [
        _daily,
        _story(
          'summer',
          startedAt: DateTime(2026, 6, 1),
          lastPostedAt: DateTime(2026, 9, 1),
        ),
        _story(
          'jeju',
          startedAt: DateTime(2026, 8, 14),
          lastPostedAt: DateTime(2026, 9, 3),
        ),
      ];

      expect(StorySuggestion.forTime(stories, at), 'jeju');
    });

    test('endedAt 이 없으면 시작 이후 전부를 덮는다', () {
      final stories = [_daily, _story('ongoing', startedAt: DateTime(2026, 8))];

      expect(StorySuggestion.forTime(stories, at), 'ongoing');
      expect(
        StorySuggestion.forTime(stories, DateTime(2026, 7, 31)),
        Story.dailyId,
      );
    });

    test('기간 양 끝은 포함한다', () {
      final stories = [_daily, _story('jeju', startedAt: at, endedAt: at)];

      expect(StorySuggestion.forTime(stories, at), 'jeju');
    });

    test('닫힌 스토리는 기간에 들어도 제안하지 않는다', () {
      final stories = [
        _daily,
        _story(
          'jeju',
          startedAt: DateTime(2026, 8, 14),
          endedAt: DateTime(2026, 8, 16),
          closed: true,
        ),
      ];

      expect(StorySuggestion.forTime(stories, at), Story.dailyId);
    });

    test('기본 스토리가 가장 최근이어도 다른 스토리를 제안한다', () {
      final stories = [
        _story(Story.dailyId, lastPostedAt: DateTime(2026, 10, 10)),
        _story('jeju', startedAt: DateTime(2026, 8)),
      ];

      expect(StorySuggestion.forTime(stories, at), 'jeju');
    });

    test('기간에 드는 스토리가 없으면 "일상"', () {
      final stories = [_daily, _story('busan', startedAt: DateTime(2026, 9))];

      expect(StorySuggestion.forTime(stories, at), Story.dailyId);
    });
  });
}
