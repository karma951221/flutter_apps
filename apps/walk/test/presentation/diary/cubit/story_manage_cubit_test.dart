import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/data/diary/drift_diary_repository.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/presentation/diary/cubit/story_manage_cubit.dart';

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

class _MockPlaces extends Mock implements PlaceSource {}

/// 실제 drift 저장소 + updateStory 호출 수.
class _SpyRepo extends DriftDiaryRepository {
  _SpyRepo(DiaryHarness h) : super(h.db, const IdGenerator(Uuid()), h.clock);

  int storyUpdates = 0;

  @override
  Future<Result<Story>> updateStory(Story story) {
    storyUpdates++;
    return super.updateStory(story);
  }
}

void main() {
  late DiaryHarness h;
  late StoryManageCubit cubit;
  late _SpyRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    h = DiaryHarness();
    repo = _SpyRepo(h);
    final useCase = DiaryUseCase(
      repo,
      _MockStore(),
      _MockPlaces(),
      prefs,
      h.clock,
    );
    cubit = StoryManageCubit(repo, useCase, h.clock)..start();
    await pumpEventQueue();
  });

  tearDown(() async {
    await cubit.close();
    await h.close();
  });

  List<String> openTitles() => [for (final s in cubit.state.open) s.title];
  List<String> archivedTitles() => [
    for (final s in cubit.state.archived) s.title,
  ];

  Future<Story> created(
    String title, {
    DateTime? startedAt,
    DateTime? endedAt,
  }) async {
    await cubit.create(
      title: title,
      startedAt: startedAt ?? diaryT0,
      endedAt: endedAt,
    );
    await pumpEventQueue();
    return cubit.state.created!;
  }

  Story byId(String id) => [
    ...cubit.state.open,
    ...cubit.state.archived,
  ].singleWhere((s) => s.id == id);

  Future<DiaryEntry> entry({
    String storyId = Story.dailyId,
    String body = '본문',
    DateTime? occurredAt,
  }) async => okValue(
    await h.repository.createEntry(
      entryDraft(storyId: storyId, body: body, occurredAt: occurredAt),
    ),
  );

  test('처음에는 기본 스토리만 열려 있다', () {
    expect([for (final s in cubit.state.open) s.id], [Story.dailyId]);
    expect(cubit.state.archived, isEmpty);
    expect(cubit.state.loading, isFalse);
  });

  group('만들기', () {
    test('종료일이 없으면 열린 스토리, 제목은 앞뒤 공백을 뗀다', () async {
      final story = await created('  제주 여행 ');

      expect(story.title, '제주 여행');
      expect(story.isOpen, isTrue);
      expect(openTitles(), contains('제주 여행'));
    });

    test('종료일이 있으면 닫힌 스토리로 보관함에 간다', () async {
      final story = await created(
        '부산',
        startedAt: DateTime(2026, 9, 1),
        endedAt: DateTime(2026, 9, 3, 23, 59),
      );

      expect(story.isOpen, isFalse);
      expect(archivedTitles(), ['부산']);
      expect(openTitles(), isNot(contains('부산')));
    });

    test('종료일이 시작일보다 빠르면 만들지 않고 알린다', () async {
      await cubit.create(
        title: '거꾸로',
        startedAt: DateTime(2026, 9, 3),
        endedAt: DateTime(2026, 9, 1),
      );
      await pumpEventQueue();

      expect(cubit.state.error, DiaryFailure.endBeforeStart);
      expect(cubit.state.created, isNull);
      expect(archivedTitles(), isEmpty);
    });
  });

  test('지난 기간의 일상 기록만 제안한다(다른 스토리 · 기간 밖 · 휴지통 제외)', () async {
    final trip = await created('출장');
    final inside = await entry(body: '안', occurredAt: DateTime(2026, 9, 2, 8));
    await entry(body: '밖', occurredAt: DateTime(2026, 9, 5, 8));
    await entry(
      storyId: trip.id,
      body: '다른 스토리',
      occurredAt: DateTime(2026, 9, 2, 9),
    );
    final trashed = await entry(
      body: '휴지통',
      occurredAt: DateTime(2026, 9, 2, 10),
    );
    await h.repository.trashEntry(trashed.id);

    final suggested = await cubit.dailyEntriesIn(
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 3, 23, 59),
    );

    expect([for (final e in suggested) e.id], [inside.id]);
  });

  test('고른 기록만 새 스토리로 옮긴다', () async {
    final past = await created(
      '여름',
      startedAt: DateTime(2026, 8, 1),
      endedAt: DateTime(2026, 8, 31, 23, 59),
    );
    final a = await entry(body: 'a', occurredAt: DateTime(2026, 8, 2));
    final b = await entry(body: 'b', occurredAt: DateTime(2026, 8, 3));
    repo.storyUpdates = 0;

    await cubit.moveIn([a.id], past.id);

    expect(okValue(await h.repository.entry(a.id)).storyId, past.id);
    expect(okValue(await h.repository.entry(b.id)).storyId, Story.dailyId);
    expect(cubit.state.error, isNull);
    expect(cubit.state.actionFailed, isFalse);
    // 닫힌(지난 기간) 스토리로 바로 옮긴다(R23) — 열었다 닫지 않는다.
    expect(repo.storyUpdates, 0);
    await pumpEventQueue();
    expect(byId(past.id).isOpen, isFalse);
    expect(byId(past.id).endedAt, DateTime(2026, 8, 31, 23, 59));
  });

  group('닫기 · 다시 열기', () {
    test('닫으면 지금 시각으로 끝나 보관함으로 간다', () async {
      final trip = await created('제주');
      h.clock.advance(const Duration(hours: 2));

      await cubit.closeStory(trip.id);
      await pumpEventQueue();

      expect(byId(trip.id).isOpen, isFalse);
      expect(byId(trip.id).endedAt, h.clock.now());
      expect(archivedTitles(), ['제주']);
    });

    test('고른 날로 닫을 수 있다', () async {
      final trip = await created('제주');
      final at = DateTime(2026, 10, 10, 23, 59);

      await cubit.closeStory(trip.id, at: at);
      await pumpEventQueue();

      expect(byId(trip.id).endedAt, at);
    });

    test('시작 전 날로는 닫지 않고 알린다', () async {
      final trip = await created('제주');

      await cubit.closeStory(
        trip.id,
        at: diaryT0.subtract(const Duration(days: 1)),
      );
      await pumpEventQueue();

      expect(cubit.state.error, DiaryFailure.endBeforeStart);
      expect(byId(trip.id).isOpen, isTrue);
    });

    test('다시 열면 종료일을 비우고 열린 목록으로 돌아온다', () async {
      final trip = await created('부산', endedAt: diaryT0);

      await cubit.reopen(trip.id);
      await pumpEventQueue();

      expect(byId(trip.id).isOpen, isTrue);
      expect(byId(trip.id).endedAt, isNull);
      expect(archivedTitles(), isEmpty);
    });

    test('기본 스토리는 닫지 않는다', () async {
      await cubit.closeStory(Story.dailyId);
      await pumpEventQueue();

      expect(cubit.state.error, DiaryFailure.defaultStoryLocked);
      expect(byId(Story.dailyId).isOpen, isTrue);
    });
  });

  group('이름 · 표지', () {
    test('이름을 바꾼다(앞뒤 공백 제거)', () async {
      final trip = await created('제주');

      await cubit.rename(trip.id, ' 제주 한 달 ');
      await pumpEventQueue();

      expect(byId(trip.id).title, '제주 한 달');
    });

    test('기본 스토리도 이름을 바꿀 수 있고, 비우면 기본 이름으로', () async {
      await cubit.rename(Story.dailyId, '하루하루');
      await pumpEventQueue();
      expect(byId(Story.dailyId).title, '하루하루');

      await cubit.rename(Story.dailyId, '  ');
      await pumpEventQueue();
      expect(byId(Story.dailyId).title, '');
    });

    test('다른 스토리의 이름은 비울 수 없다', () async {
      final trip = await created('제주');

      await cubit.rename(trip.id, '  ');
      await pumpEventQueue();

      expect(byId(trip.id).title, '제주');
    });

    test('표지를 고르고, null 이면 자동 표지로 되돌린다', () async {
      final trip = await created('제주');
      await h.repository.createEntry(
        entryDraft(storyId: trip.id, media: [photoMedia('p1')]),
      );

      await cubit.setCover(trip.id, 'p1');
      await pumpEventQueue();
      expect(byId(trip.id).coverMediaId, 'p1');

      await cubit.setCover(trip.id, null);
      await pumpEventQueue();
      expect(byId(trip.id).coverMediaId, isNull);
    });

    test('표지 후보는 그 스토리의 살아 있는 기록 미디어만, 최신 기록부터', () async {
      final trip = await created('제주');
      await h.repository.createEntry(
        entryDraft(
          storyId: trip.id,
          occurredAt: diaryT0.subtract(const Duration(hours: 1)),
          media: [photoMedia('old')],
        ),
      );
      await h.repository.createEntry(
        entryDraft(
          storyId: trip.id,
          media: [photoMedia('new'), videoMedia('v')],
        ),
      );
      final gone = okValue(
        await h.repository.createEntry(
          entryDraft(storyId: trip.id, media: [photoMedia('trashed')]),
        ),
      );
      await h.repository.trashEntry(gone.id);
      await h.repository.createEntry(entryDraft(media: [photoMedia('daily')]));

      final candidates = await cubit.coverCandidates(trip.id);

      expect([for (final m in candidates) m.id], ['new', 'v', 'old']);
    });
  });

  group('삭제', () {
    test('스토리를 지우면 그 기록은 휴지통으로 가고 목록에서 빠진다', () async {
      final trip = await created('제주');
      final e = await entry(storyId: trip.id);

      await cubit.delete(trip.id);
      await pumpEventQueue();

      expect(openTitles(), isNot(contains('제주')));
      final trashed = okValue(await h.repository.entry(e.id));
      expect(trashed.isTrashed, isTrue);
      expect(trashed.storyId, Story.dailyId);
    });

    test('기본 스토리는 지우지 않는다', () async {
      await cubit.delete(Story.dailyId);
      await pumpEventQueue();

      expect(cubit.state.error, DiaryFailure.defaultStoryLocked);
      expect(byId(Story.dailyId), isNotNull);
    });
  });
}
