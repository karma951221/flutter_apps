import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/diary/cubit/diary_timeline_cubit.dart';

import '../../../support/diary_fixtures.dart';

class _MockRepo extends Mock implements DiaryRepository {}

void main() {
  late DiaryHarness h;

  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  setUp(() => h = DiaryHarness());

  tearDown(() => h.close());

  Future<DiaryTimelineCubit> started() async {
    final cubit = DiaryTimelineCubit(h.repository)..start();
    addTearDown(cubit.close);
    await pumpEventQueue();
    return cubit;
  }

  Future<Story> story(String title, {DateTime? endedAt}) async => okValue(
    await h.repository.createStory(
      title: title,
      startedAt: diaryT0,
      endedAt: endedAt,
    ),
  );

  List<String> bodies(DiaryTimelineCubit c) => [
    for (final e in c.state.entries) e.body,
  ];

  test('열린 스토리와 보관함을 나눠 둔다', () async {
    final trip = await story('제주');
    h.clock.advance(const Duration(minutes: 1));
    await h.repository.createEntry(entryDraft(storyId: trip.id));
    await story('출장', endedAt: diaryT0);

    final cubit = await started();

    expect(cubit.state.loading, isFalse);
    expect(
      [for (final s in cubit.state.openStories) s.id],
      [trip.id, Story.dailyId],
    );
    expect([for (final s in cubit.state.archived) s.title], ['출장']);
  });

  test('항상 모든 스토리의 기록을 최신순으로 받는다', () async {
    final trip = await story('제주');
    await h.repository.createEntry(
      entryDraft(storyId: trip.id, body: '바다', occurredAt: diaryT0),
    );
    await h.repository.createEntry(
      entryDraft(
        body: '출근',
        occurredAt: diaryT0.subtract(const Duration(hours: 1)),
      ),
    );

    final cubit = await started();

    expect(bodies(cubit), ['바다', '출근']);
  });

  test('저장 · 삭제 · 복원이 열린 타임라인에 바로 반영된다', () async {
    final cubit = await started();
    expect(cubit.state.entries, isEmpty);

    final entry = okValue(
      await h.repository.createEntry(entryDraft(body: '산책')),
    );
    await pumpEventQueue();
    expect(bodies(cubit), ['산책']);

    await h.repository.trashEntry(entry.id);
    await pumpEventQueue();
    expect(cubit.state.entries, isEmpty);

    await h.repository.restoreEntry(entry.id);
    await pumpEventQueue();
    expect(bodies(cubit), ['산책']);
  });

  group('실패', () {
    late _MockRepo repo;
    late StreamController<List<Story>> storyStream;
    late StreamController<List<DiaryEntry>> entryStream;

    setUp(() {
      repo = _MockRepo();
      storyStream = StreamController<List<Story>>();
      entryStream = StreamController<List<DiaryEntry>>();
      when(repo.watchStories).thenAnswer((_) => storyStream.stream);
      when(
        () => repo.watchEntries(any()),
      ).thenAnswer((_) => entryStream.stream);
    });

    test('전체 필터 하나만 구독한다', () async {
      final cubit = DiaryTimelineCubit(repo)..start();
      addTearDown(cubit.close);
      await pumpEventQueue();
      entryStream.add([_entry('출근')]);
      await pumpEventQueue();

      verify(() => repo.watchEntries(const EntryFilter.all())).called(1);
      expect(cubit.state.loading, isFalse);
      expect(bodies(cubit), ['출근']);
    });

    test('기록 스트림이 실패하면 로딩을 끝내고 실패를 표시한다', () async {
      final cubit = DiaryTimelineCubit(repo)..start();
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.loading, isTrue);

      entryStream.addError(Exception('db'));
      await pumpEventQueue();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.failed, isTrue);
    });

    test('스토리 스트림이 실패해도 로딩을 끝내고 실패를 표시한다', () async {
      final cubit = DiaryTimelineCubit(repo)..start();
      addTearDown(cubit.close);
      await pumpEventQueue();

      storyStream.addError(Exception('db'));
      await pumpEventQueue();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.failed, isTrue);
    });
  });
}

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
