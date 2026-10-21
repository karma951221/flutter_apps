import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/entry_draft.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/presentation/diary/cubit/filtered_entries_cubit.dart';

import '../../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;

  setUp(() => h = DiaryHarness());

  tearDown(() => h.close());

  Future<FilteredEntriesCubit> opened(EntryFilter filter) async {
    final cubit = FilteredEntriesCubit(h.repository, filter)..start();
    addTearDown(cubit.close);
    await pumpEventQueue();
    return cubit;
  }

  Future<String> create(EntryDraft draft) async {
    final id = okValue(await h.repository.createEntry(draft)).id;
    await pumpEventQueue();
    return id;
  }

  Future<void> trash(String id) async {
    okValue(await h.repository.trashEntry(id));
    await pumpEventQueue();
  }

  Future<void> restore(String id) async {
    okValue(await h.repository.restoreEntry(id));
    await pumpEventQueue();
  }

  List<String> ids(FilteredEntriesCubit c) => [
    for (final e in c.state.entries) e.id,
  ];

  /// tag · place 그룹이 같은 시나리오를 돈다.
  void scenarios({
    required EntryFilter filter,
    required EntryDraft Function(String body) matching,
    required EntryDraft Function(String body) other,
  }) {
    test('열린 상태에서 기록을 추가하면 +1, 다른 기록은 무시', () async {
      final a = await create(matching('a'));
      final c = await opened(filter);
      expect(ids(c), [a]);
      expect(c.state.loading, isFalse);

      h.clock.advance(const Duration(minutes: 1));
      final b = await create(matching('b'));
      await create(other('c'));

      expect(ids(c), [b, a]);
    });

    test('휴지통으로 보내면 -1, 복원하면 +1', () async {
      final a = await create(matching('a'));
      h.clock.advance(const Duration(minutes: 1));
      final b = await create(matching('b'));
      final c = await opened(filter);

      await trash(b);
      expect(ids(c), [a]);

      await restore(b);
      expect(ids(c), [b, a]);
    });

    test('마지막 기록이 휴지통으로 가면 빈 상태', () async {
      final a = await create(matching('a'));
      final c = await opened(filter);

      await trash(a);

      expect(c.state.entries, isEmpty);
      expect(c.state.loading, isFalse);
      expect(c.state.failed, isFalse);
    });

    test('스토리를 넘나든다 — 스토리 이름표용 목록도 받는다', () async {
      final trip = okValue(
        await h.repository.createStory(title: '제주', startedAt: diaryT0),
      );
      final a = await create(matching('a'));
      h.clock.advance(const Duration(minutes: 1));
      final b = await create(matching('b').copyWith(storyId: trip.id));
      final c = await opened(filter);

      expect(ids(c), [b, a]);
      expect({for (final s in c.state.stories) s.id}, {Story.dailyId, trip.id});
    });
  }

  group('태그', () {
    scenarios(
      filter: const EntryFilter.tag('제주'),
      matching: (body) => entryDraft(body: body, tags: ['제주', '바다']),
      other: (body) => entryDraft(body: body, tags: ['서울']),
    );
  });

  group('장소', () {
    scenarios(
      filter: const EntryFilter.place('애월읍'),
      matching: (body) => entryDraft(
        body: body,
        location: const EntryLocation(placeName: '애월읍'),
      ),
      other: (body) => entryDraft(
        body: body,
        location: const EntryLocation(placeName: '한림읍'),
      ),
    );
  });
}
