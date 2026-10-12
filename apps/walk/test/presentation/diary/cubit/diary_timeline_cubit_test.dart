import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/diary_view_mode.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/diary/cubit/diary_timeline_cubit.dart';

import '../../../support/diary_fixtures.dart';

class _MockRepo extends Mock implements DiaryRepository {}

/// 저장이 늘 실패하는 설정. 읽기는 기본값.
class _FailingPrefs implements DiaryPreferences {
  @override
  String? get lastViewedStoryId => null;
  @override
  DiaryViewMode get viewMode => DiaryViewMode.prose;
  @override
  TrashRetention get trashRetention => TrashRetention.fallback;
  @override
  Future<void> setLastViewedStoryId(String? id) =>
      Future.error(Exception('io'));
  @override
  Future<void> setViewMode(DiaryViewMode v) => Future.error(Exception('io'));
  @override
  Future<void> setTrashRetention(TrashRetention v) =>
      Future.error(Exception('io'));
}

void main() {
  late DiaryHarness h;
  late PrefsDiaryPreferences prefs;

  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    h = DiaryHarness();
  });

  tearDown(() => h.close());

  Future<DiaryTimelineCubit> started() async {
    final cubit = DiaryTimelineCubit(h.repository, prefs)..start();
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

  test('처음 열면 전체 · 줄글, 열린 스토리와 보관함을 나눠 둔다', () async {
    final trip = await story('제주');
    h.clock.advance(const Duration(minutes: 1));
    await h.repository.createEntry(entryDraft(storyId: trip.id));
    await story('출장', endedAt: diaryT0);

    final cubit = await started();

    expect(cubit.state.selectedStoryId, isNull);
    expect(cubit.state.viewMode, DiaryViewMode.prose);
    expect(cubit.state.loading, isFalse);
    expect(
      [for (final s in cubit.state.openStories) s.id],
      [trip.id, Story.dailyId],
    );
    expect([for (final s in cubit.state.archived) s.title], ['출장']);
  });

  test('마지막으로 보던 스토리와 보기 모드를 복원한다', () async {
    final trip = await story('제주');
    await h.repository.createEntry(entryDraft(storyId: trip.id, body: '바다'));
    await h.repository.createEntry(entryDraft(body: '출근'));
    await prefs.setLastViewedStoryId(trip.id);
    await prefs.setViewMode(DiaryViewMode.feed);

    final cubit = await started();

    expect(cubit.state.selectedStoryId, trip.id);
    expect(cubit.state.viewMode, DiaryViewMode.feed);
    expect(bodies(cubit), ['바다']);
  });

  test('지워진 스토리를 보던 중이었으면 전체로 연다', () async {
    await h.repository.createEntry(entryDraft(body: '출근'));
    await prefs.setLastViewedStoryId('gone');

    final cubit = await started();

    expect(cubit.state.selectedStoryId, isNull);
    expect(bodies(cubit), ['출근']);
    expect(prefs.lastViewedStoryId, isNull);
  });

  test('보던 스토리가 삭제되면 전체로 돌아간다', () async {
    final trip = await story('제주');
    await h.repository.createEntry(entryDraft(body: '출근'));
    final cubit = await started();
    cubit.selectStory(trip.id);
    await pumpEventQueue();

    await h.repository.deleteStory(trip.id);
    await pumpEventQueue();

    expect(cubit.state.selectedStoryId, isNull);
    expect(bodies(cubit), ['출근']);
  });

  test('스토리를 바꾸면 그 스토리 기록만, 전체(null)면 모든 기록', () async {
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

    cubit.selectStory(Story.dailyId);
    await pumpEventQueue();
    expect(cubit.state.selectedStoryId, Story.dailyId);
    expect(bodies(cubit), ['출근']);
    expect(prefs.lastViewedStoryId, Story.dailyId);

    cubit.selectStory(null);
    await pumpEventQueue();
    expect(cubit.state.selectedStoryId, isNull);
    expect(bodies(cubit), ['바다', '출근']);
    expect(prefs.lastViewedStoryId, isNull);
  });

  test('보기 모드를 바꾸면 저장해 다음에 연다', () async {
    final cubit = await started();

    cubit.setViewMode(DiaryViewMode.reels);
    await pumpEventQueue();

    expect(cubit.state.viewMode, DiaryViewMode.reels);
    expect(prefs.viewMode, DiaryViewMode.reels);
    final next = await started();
    expect(next.state.viewMode, DiaryViewMode.reels);
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

  test('스토리를 바꾼 직후 옛 스토리 스트림의 늦은 이벤트는 버린다', () async {
    final repo = _MockRepo();
    final streams = <EntryFilter, StreamController<List<DiaryEntry>>>{};
    when(repo.watchStories).thenAnswer((_) => const Stream.empty());
    when(() => repo.watchEntries(any())).thenAnswer((inv) {
      final filter = inv.positionalArguments.single as EntryFilter;
      return (streams[filter] = StreamController<List<DiaryEntry>>()).stream;
    });
    final cubit = DiaryTimelineCubit(repo, prefs)..start();
    addTearDown(cubit.close);
    await pumpEventQueue();
    final all = streams[const EntryFilter.all()]!;

    cubit.selectStory('trip');
    final trip = streams[const EntryFilter.story('trip')]!;
    all.add([_entry('옛 전체')]);
    await pumpEventQueue();
    expect(cubit.state.entries, isEmpty);
    expect(cubit.state.loading, isTrue);

    trip.add([_entry('바다')]);
    await pumpEventQueue();
    expect(bodies(cubit), ['바다']);
    expect(cubit.state.loading, isFalse);
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

    test('기록 스트림이 실패하면 로딩을 끝내고 실패를 표시한다', () async {
      final cubit = DiaryTimelineCubit(repo, prefs)..start();
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.loading, isTrue);

      entryStream.addError(Exception('db'));
      await pumpEventQueue();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.failed, isTrue);
    });

    test('스토리 스트림이 실패해도 로딩을 끝내고 실패를 표시한다', () async {
      final cubit = DiaryTimelineCubit(repo, prefs)..start();
      addTearDown(cubit.close);
      await pumpEventQueue();

      storyStream.addError(Exception('db'));
      await pumpEventQueue();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.failed, isTrue);
    });

    test('다른 스토리를 고르면 실패 표시를 지우고 다시 받는다', () async {
      final cubit = DiaryTimelineCubit(repo, prefs)..start();
      addTearDown(cubit.close);
      await pumpEventQueue();
      entryStream.addError(Exception('db'));
      await pumpEventQueue();

      entryStream = StreamController<List<DiaryEntry>>();
      cubit.selectStory('trip');
      entryStream.add([_entry('바다')]);
      await pumpEventQueue();

      expect(cubit.state.failed, isFalse);
      expect(bodies(cubit), ['바다']);
    });

    test('설정 저장이 실패해도 고른 스토리 · 보기 모드는 바뀐다', () async {
      final cubit = DiaryTimelineCubit(repo, _FailingPrefs())..start();
      addTearDown(cubit.close);
      await pumpEventQueue();
      entryStream = StreamController<List<DiaryEntry>>();

      cubit
        ..selectStory('trip')
        ..setViewMode(DiaryViewMode.feed);
      await pumpEventQueue();

      expect(cubit.state.selectedStoryId, 'trip');
      expect(cubit.state.viewMode, DiaryViewMode.feed);
    });

    test('이미 보고 있는 스토리를 다시 고르면 아무 일도 없다', () async {
      final cubit = DiaryTimelineCubit(repo, prefs)..start();
      addTearDown(cubit.close);
      await pumpEventQueue();
      entryStream.add([_entry('출근')]);
      await pumpEventQueue();

      cubit.selectStory(null);
      await pumpEventQueue();

      verify(() => repo.watchEntries(any())).called(1);
      expect(cubit.state.loading, isFalse);
      expect(bodies(cubit), ['출근']);
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
