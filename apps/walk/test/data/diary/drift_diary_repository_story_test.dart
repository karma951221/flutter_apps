import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/usecase/story_order.dart';

import '../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;

  setUp(() => h = DiaryHarness());
  tearDown(() => h.close());

  Future<Story> stored(String id) async =>
      (await h.repository.watchStories().first).singleWhere((s) => s.id == id);

  group('createStory', () {
    test('endedAt 없이 만들면 open, id · createdAt 을 채운다', () async {
      final story = okValue(
        await h.repository.createStory(
          title: '제주 여행',
          startedAt: DateTime(2026, 10, 1),
        ),
      );

      expect(story.id, isNot(Story.dailyId));
      expect(story.id, isNotEmpty);
      expect(story.title, '제주 여행');
      expect(story.status, StoryStatus.open);
      expect(story.startedAt, DateTime(2026, 10, 1));
      expect(story.endedAt, isNull);
      expect(story.lastPostedAt, isNull);
      expect(story.createdAt, diaryT0);
      expect(await stored(story.id), story);
    });

    test('endedAt 이 있으면 closed 로 만든다', () async {
      final story = okValue(
        await h.repository.createStory(
          title: '출장',
          startedAt: DateTime(2026, 9, 1),
          endedAt: DateTime(2026, 9, 3),
        ),
      );

      expect(story.status, StoryStatus.closed);
      expect(story.endedAt, DateTime(2026, 9, 3));
      expect((await stored(story.id)).status, StoryStatus.closed);
    });

    test('endedAt 이 startedAt 보다 앞이면 endBeforeStart', () async {
      final result = await h.repository.createStory(
        title: '출장',
        startedAt: DateTime(2026, 9, 3),
        endedAt: DateTime(2026, 9, 1),
      );

      expect(
        errFailure(result),
        isDiaryFailure(DiaryFailure.endBeforeStart.name),
      );
      expect(await h.repository.watchStories().first, hasLength(1));
    });
  });

  group('updateStory', () {
    late Story jeju;
    setUp(() async {
      jeju = okValue(
        await h.repository.createStory(
          title: '제주',
          startedAt: DateTime(2026, 10, 1),
        ),
      );
    });

    test('닫기 → 다시 열기', () async {
      final closed = okValue(jeju.close(DateTime(2026, 10, 5)));
      okValue(await h.repository.updateStory(closed));
      final afterClose = await stored(jeju.id);
      expect(afterClose.status, StoryStatus.closed);
      expect(afterClose.endedAt, DateTime(2026, 10, 5));

      okValue(await h.repository.updateStory(okValue(afterClose.reopen())));
      final afterReopen = await stored(jeju.id);
      expect(afterReopen.status, StoryStatus.open);
      expect(afterReopen.endedAt, isNull);
    });

    test('이름 · 표지를 바꾼다', () async {
      okValue(
        await h.repository.updateStory(
          Story(
            id: jeju.id,
            title: '제주 한 달',
            status: jeju.status,
            startedAt: jeju.startedAt,
            coverMediaId: 'm1',
            createdAt: jeju.createdAt,
          ),
        ),
      );

      final after = await stored(jeju.id);
      expect(after.title, '제주 한 달');
      expect(after.coverMediaId, 'm1');
      expect(after.createdAt, jeju.createdAt);
    });

    test('없는 스토리는 notFound', () async {
      final ghost = Story(
        id: 'ghost',
        title: 'x',
        status: StoryStatus.open,
        startedAt: diaryT0,
        createdAt: diaryT0,
      );

      expect(
        errFailure(await h.repository.updateStory(ghost)),
        isA<NotFoundFailure>(),
      );
    });

    test('기본 스토리를 닫으면 defaultStoryLocked', () async {
      final daily = await stored(Story.dailyId);
      final closed = Story(
        id: daily.id,
        title: daily.title,
        status: StoryStatus.closed,
        startedAt: daily.startedAt,
        endedAt: diaryT0,
        createdAt: daily.createdAt,
      );

      expect(
        errFailure(await h.repository.updateStory(closed)),
        isDiaryFailure(DiaryFailure.defaultStoryLocked.name),
      );
      expect((await stored(Story.dailyId)).status, StoryStatus.open);
    });
  });

  test('watchStories 는 저장 뒤 새 목록을 내보낸다', () async {
    final events = h.repository.watchStories();
    final expectation = expectLater(
      events.map((list) => list.length),
      emitsInOrder([1, 2]),
    );
    await pumpEventQueue();
    await h.repository.createStory(title: '제주', startedAt: diaryT0);
    await expectation;
  });

  test('스토리 바 순서: 기록을 남긴 스토리가 앞, 닫은 것은 보관함', () async {
    final jeju = okValue(
      await h.repository.createStory(title: '제주', startedAt: diaryT0),
    );
    h.clock.advance(const Duration(minutes: 1));
    final work = okValue(
      await h.repository.createStory(title: '출장', startedAt: diaryT0),
    );
    h.clock.advance(const Duration(minutes: 1));
    final old = okValue(
      await h.repository.createStory(
        title: '지난 여행',
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 1, 5),
      ),
    );
    h.clock.advance(const Duration(minutes: 1));
    okValue(await h.repository.createEntry(entryDraft(storyId: jeju.id)));

    final split = StoryOrder.split(await h.repository.watchStories().first);

    // jeju(방금 기록) → work(만든 시각) → daily(가장 먼저 만듦).
    expect(split.open.map((s) => s.id), [jeju.id, work.id, Story.dailyId]);
    expect(split.archived.map((s) => s.id), [old.id]);
  });

  group('entriesBetween', () {
    test('기간 안 · 해당 스토리 · 휴지통 제외만 돌려준다', () async {
      final jeju = okValue(
        await h.repository.createStory(
          title: '제주',
          startedAt: DateTime(2026, 10, 1),
        ),
      );
      Future<String> add(String storyId, DateTime at) async => okValue(
        await h.repository.createEntry(
          entryDraft(storyId: storyId, occurredAt: at),
        ),
      ).id;

      final first = await add(Story.dailyId, DateTime(2026, 10, 2, 8));
      final last = await add(Story.dailyId, DateTime(2026, 10, 4, 20));
      await add(Story.dailyId, DateTime(2026, 9, 30, 23)); // 기간 밖
      await add(Story.dailyId, DateTime(2026, 10, 5, 1)); // 기간 밖
      await add(jeju.id, DateTime(2026, 10, 3)); // 다른 스토리
      final trashed = await add(Story.dailyId, DateTime(2026, 10, 3));
      await h.trashDirectly(trashed);

      final found = await h.repository.entriesBetween(
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 4, 23, 59),
        storyId: Story.dailyId,
      );

      expect(found.map((e) => e.id), [last, first]);
    });
  });

  test('watchEntries(story) 는 그 스토리 기록만', () async {
    final jeju = okValue(
      await h.repository.createStory(title: '제주', startedAt: diaryT0),
    );
    final mine = okValue(
      await h.repository.createEntry(entryDraft(storyId: jeju.id)),
    );
    okValue(await h.repository.createEntry(entryDraft()));

    final list = await h.repository
        .watchEntries(EntryFilter.story(jeju.id))
        .first;
    expect(list.map((e) => e.id), [mine.id]);
  });
}
