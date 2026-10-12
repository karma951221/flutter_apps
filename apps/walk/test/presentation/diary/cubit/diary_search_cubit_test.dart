import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/named_count.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/diary/cubit/diary_search_cubit.dart';
import 'package:walk/presentation/diary/cubit/diary_search_state.dart';

import '../../../support/diary_fixtures.dart';

class _MockRepo extends Mock implements DiaryRepository {}

DiaryEntry _entry(String body) => DiaryEntry(
  id: body,
  storyId: Story.dailyId,
  body: body,
  occurredAt: diaryT0,
  createdAt: diaryT0,
  updatedAt: diaryT0,
  media: const [],
  tags: const [],
);

NamedCount _count(String name, int count) =>
    NamedCount(name: name, count: count, lastUsedAt: diaryT0);

void main() {
  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  group('디바운스 · 탭(가짜 시간)', () {
    late _MockRepo repo;

    setUp(() {
      repo = _MockRepo();
      when(() => repo.watchEntries(any())).thenAnswer(
        (inv) => Stream.value([
          _entry('${(inv.positionalArguments.single as BodyEntries).query} 결과'),
        ]),
      );
      when(
        () => repo.watchTagCounts(query: any(named: 'query')),
      ).thenAnswer((_) => Stream.value([_count('제주', 3)]));
      when(
        () => repo.watchPlaceCounts(query: any(named: 'query')),
      ).thenAnswer((_) => Stream.value([_count('애월읍', 2)]));
      when(
        () =>
            repo.watchStoryMatches(any(), dailyTitle: any(named: 'dailyTitle')),
      ).thenAnswer((_) => const Stream.empty());
    });

    DiarySearchCubit cubit() => DiarySearchCubit(repo, dailyTitle: '일상');

    test('처음엔 글 탭 · 빈 입력이라 아무것도 조회하지 않는다', () {
      fakeAsync((async) {
        final c = cubit();
        async.elapse(const Duration(seconds: 1));

        expect(c.state.scope, SearchScope.body);
        expect(c.state.loading, isFalse);
        verifyZeroInteractions(repo);
        unawaited(c.close());
      });
    });

    test('탭 4개는 각자 맞는 조회를 부른다', () {
      fakeAsync((async) {
        final c = cubit()..setQuery('제');
        async.elapse(const Duration(milliseconds: 300));
        verify(() => repo.watchEntries(const EntryFilter.body('제'))).called(1);

        c.setScope(SearchScope.story);
        async.flushMicrotasks();
        verify(() => repo.watchStoryMatches('제', dailyTitle: '일상')).called(1);

        c.setScope(SearchScope.tag);
        async.flushMicrotasks();
        verify(() => repo.watchTagCounts(query: '제')).called(1);
        expect(namedCounts(c.state.suggestions), ['제주 3']);

        c.setScope(SearchScope.place);
        async.flushMicrotasks();
        verify(() => repo.watchPlaceCounts(query: '제')).called(1);
        expect(namedCounts(c.state.suggestions), ['애월읍 2']);
        unawaited(c.close());
      });
    });

    test('입력 후 299ms 에는 조회하지 않고 300ms 에 한 번 조회한다', () {
      fakeAsync((async) {
        final c = cubit()..setQuery('밥');
        async.elapse(const Duration(milliseconds: 299));
        verifyNever(() => repo.watchEntries(any()));
        expect(c.state.query, '밥');

        async.elapse(const Duration(milliseconds: 1));
        verify(() => repo.watchEntries(const EntryFilter.body('밥'))).called(1);
        expect([for (final e in c.state.bodyResults) e.body], ['밥 결과']);
        expect(c.state.searched, '밥');
        unawaited(c.close());
      });
    });

    test('빠르게 이어 친 입력은 마지막 것만 조회한다', () {
      fakeAsync((async) {
        final c = cubit()..setQuery('ㅂ');
        async.elapse(const Duration(milliseconds: 100));
        c.setQuery('바');
        async.elapse(const Duration(milliseconds: 200));
        c.setQuery('밥');
        async.elapse(const Duration(milliseconds: 300));

        expect(verify(() => repo.watchEntries(captureAny())).captured, [
          const EntryFilter.body('밥'),
        ]);
        unawaited(c.close());
      });
    });

    test('빈 · 공백 입력이면 글 · 스토리는 조회하지 않고 결과를 비운다', () {
      fakeAsync((async) {
        final c = cubit()..setQuery('밥');
        async.elapse(const Duration(milliseconds: 300));
        expect(c.state.bodyResults, hasLength(1));

        c.setQuery('   ');
        async.elapse(const Duration(milliseconds: 300));
        expect(c.state.bodyResults, isEmpty);
        expect(c.state.searched, '');
        expect(c.state.loading, isFalse);

        c.setScope(SearchScope.story);
        async.elapse(const Duration(milliseconds: 300));
        verify(() => repo.watchEntries(any())).called(1);
        verifyNever(
          () => repo.watchStoryMatches(
            any(),
            dailyTitle: any(named: 'dailyTitle'),
          ),
        );
        unawaited(c.close());
      });
    });

    test('빈 입력이면 태그 · 장소는 바로 상위 추천을 보인다(기본 개수)', () {
      fakeAsync((async) {
        final c = cubit()..setScope(SearchScope.tag);
        async.flushMicrotasks();

        verify(() => repo.watchTagCounts()).called(1);
        expect(namedCounts(c.state.suggestions), ['제주 3']);

        c.setScope(SearchScope.place);
        async.flushMicrotasks();
        verify(() => repo.watchPlaceCounts()).called(1);
        expect(namedCounts(c.state.suggestions), ['애월읍 2']);
        unawaited(c.close());
      });
    });

    test('입력을 바꾼 뒤 옛 입력의 늦은 응답은 버린다', () {
      fakeAsync((async) {
        final streams = <String, StreamController<List<DiaryEntry>>>{};
        when(() => repo.watchEntries(any())).thenAnswer((inv) {
          final q = (inv.positionalArguments.single as BodyEntries).query;
          return (streams[q] = StreamController<List<DiaryEntry>>()).stream;
        });
        final c = cubit()..setQuery('바다');
        async.elapse(const Duration(milliseconds: 300));
        c.setQuery('바람');
        async.elapse(const Duration(milliseconds: 300));

        streams['바다']!.add([_entry('바다 늦은 결과')]);
        async.flushMicrotasks();
        expect(c.state.bodyResults, isEmpty);

        streams['바람']!.add([_entry('바람 결과')]);
        async.flushMicrotasks();
        expect([for (final e in c.state.bodyResults) e.body], ['바람 결과']);
        expect(c.state.searched, '바람');
        unawaited(c.close());
      });
    });

    test('탭을 바꾼 뒤 옛 탭의 늦은 응답은 버린다', () {
      fakeAsync((async) {
        final tags = StreamController<List<NamedCount>>();
        when(
          () => repo.watchTagCounts(query: any(named: 'query')),
        ).thenAnswer((_) => tags.stream);
        final c = cubit()..setScope(SearchScope.tag);
        async.flushMicrotasks();
        c.setScope(SearchScope.place);
        async.flushMicrotasks();

        tags.add([_count('늦은 태그', 9)]);
        async.flushMicrotasks();
        expect(namedCounts(c.state.suggestions), ['애월읍 2']);
        unawaited(c.close());
      });
    });

    test('조회가 실패하면 실패 상태', () {
      fakeAsync((async) {
        when(
          () => repo.watchTagCounts(query: any(named: 'query')),
        ).thenAnswer((_) => Stream.error(Exception('db')));
        final c = cubit()..setScope(SearchScope.tag);
        async.flushMicrotasks();

        expect(c.state.failed, isTrue);
        expect(c.state.loading, isFalse);
        unawaited(c.close());
      });
    });
  });

  group('추천 · 결과는 기록 변경을 바로 반영한다(메모리 DB)', () {
    late DiaryHarness h;

    setUp(() => h = DiaryHarness());
    tearDown(() => h.close());

    Future<DiarySearchCubit> opened(SearchScope scope, String query) async {
      final c = DiarySearchCubit(
        h.repository,
        dailyTitle: '일상',
        debounce: Duration.zero,
      );
      addTearDown(c.close);
      c
        ..setScope(scope)
        ..setQuery(query);
      await pumpEventQueue();
      return c;
    }

    Future<String> create({
      List<String> tags = const [],
      String? place,
      String body = '본문',
    }) async {
      final e = okValue(
        await h.repository.createEntry(
          entryDraft(
            body: body,
            tags: tags,
            location: place == null ? null : EntryLocation(placeName: place),
          ),
        ),
      );
      await pumpEventQueue();
      return e.id;
    }

    Future<void> trash(String id) async {
      okValue(await h.repository.trashEntry(id));
      await pumpEventQueue();
    }

    Future<void> restore(String id) async {
      okValue(await h.repository.restoreEntry(id));
      await pumpEventQueue();
    }

    test('태그 추천: 휴지통으로 보내면 개수가 줄고, 복원하면 는다', () async {
      final a = await create(tags: ['제주']);
      await create(tags: ['제주']);
      final c = await opened(SearchScope.tag, '');
      expect(namedCounts(c.state.suggestions), ['제주 2']);

      await trash(a);
      expect(namedCounts(c.state.suggestions), ['제주 1']);

      await restore(a);
      expect(namedCounts(c.state.suggestions), ['제주 2']);

      await create(tags: ['제주']);
      expect(namedCounts(c.state.suggestions), ['제주 3']);
    });

    test('장소 추천: 마지막 기록을 휴지통으로 보내면 사라지고, 복원하면 돌아온다', () async {
      final a = await create(place: '애월읍');
      final c = await opened(SearchScope.place, '애월');
      expect(namedCounts(c.state.suggestions), ['애월읍 1']);

      await trash(a);
      expect(c.state.suggestions, isEmpty);

      await restore(a);
      expect(namedCounts(c.state.suggestions), ['애월읍 1']);
    });

    test('스토리 결과의 기록 수도 휴지통 · 복원을 따른다', () async {
      final a = await create();
      await create();
      final c = await opened(SearchScope.story, '일상');
      expect([for (final s in c.state.stories) s.count], [2]);

      await trash(a);
      expect([for (final s in c.state.stories) s.count], [1]);

      await restore(a);
      expect([for (final s in c.state.stories) s.count], [2]);
    });

    test('글 결과: 휴지통 기록은 빠지고 복원하면 다시 나온다', () async {
      final a = await create(body: '바다를 봤다');
      final c = await opened(SearchScope.body, '바다');
      expect([for (final e in c.state.bodyResults) e.id], [a]);

      await trash(a);
      expect(c.state.bodyResults, isEmpty);

      await restore(a);
      expect([for (final e in c.state.bodyResults) e.id], [a]);
    });
  });
}
