import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';

import '../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;

  setUp(() => h = DiaryHarness());
  tearDown(() => h.close());

  Future<DiaryEntry> create({
    String storyId = Story.dailyId,
    String body = '본문',
    DateTime? occurredAt,
    EntryLocation? location,
    List<String> tags = const [],
  }) async => okValue(
    await h.repository.createEntry(
      entryDraft(
        storyId: storyId,
        body: body,
        occurredAt: occurredAt,
        location: location,
        tags: tags,
      ),
    ),
  );

  Future<Story> newStory(String title, {DateTime? endedAt}) async => okValue(
    await h.repository.createStory(
      title: title,
      startedAt: DateTime(2026, 1, 1),
      endedAt: endedAt,
    ),
  );

  Future<List<String>> idsIn(EntryFilter filter) async => [
    for (final e in await h.repository.watchEntries(filter).first) e.id,
  ];

  Future<List<String>> searchBody(String q) => idsIn(EntryFilter.body(q));

  group('글(body)', () {
    test('부분 일치', () async {
      final hit = await create(body: '협재 바다에서 수영');
      await create(body: '한라산 등반');

      expect(await searchBody('바다'), [hit.id]);
    });

    test('ASCII 는 대소문자를 무시한다', () async {
      final hit = await create(body: 'Jeju Olle trail');

      expect(await searchBody('jeju olle'), [hit.id]);
      expect(await searchBody('TRAIL'), [hit.id]);
    });

    test('% · _ · \\ 는 글자 그대로만 매치한다', () async {
      final percent = await create(body: '배터리 100% 충전');
      await create(body: '배터리 1000 충전');
      final under = await create(body: 'a_b 변수');
      await create(body: 'axb 변수');
      final slash = await create(body: r'경로 c:\dir 에 저장');
      await create(body: '경로 c:dir 에 저장');
      await create(body: r'경로 c:\\dir 이중');

      expect(await searchBody('100%'), [percent.id]);
      expect(await searchBody('a_b'), [under.id]);
      expect(await searchBody(r'c:\dir'), [slash.id]);
      expect(await searchBody('%'), [percent.id]);
      expect(await searchBody('_'), [under.id]);
    });

    test('휴지통 기록은 빠진다', () async {
      final kept = await create(body: '귤 먹음');
      final trashed = await create(body: '귤 또 먹음');
      okValue(await h.repository.trashEntry(trashed.id));

      expect(await searchBody('귤'), [kept.id]);
    });

    test('occurredAt 최신순, 스토리를 넘나든다', () async {
      final trip = await newStory('제주');
      final old = await create(body: '귤', occurredAt: DateTime(2026, 9, 1));
      final newest = await create(
        storyId: trip.id,
        body: '귤',
        occurredAt: DateTime(2026, 10, 5),
      );
      final middle = await create(body: '귤', occurredAt: DateTime(2026, 9, 20));

      expect(await searchBody('귤'), [newest.id, middle.id, old.id]);
    });

    test('한글 · 이모지 · 1만 자 본문도 깨지지 않는다', () async {
      final emoji = await create(body: '오늘 산책 🐶🌊 최고');
      final long = await create(body: '${'가' * 9990}끝에있는말');
      await create(body: '다른 글');

      expect(await searchBody('🌊'), [emoji.id]);
      expect(await searchBody('산책 🐶'), [emoji.id]);
      expect(await searchBody('끝에있는'), [long.id]);
      expect(await searchBody('가가가'), [long.id]);
      // 한글 조합 중 낱자(ㄱ)는 완성형과 다른 글자라 매치하지 않는다.
      expect(await searchBody('ㄱ'), isEmpty);
    });
  });

  group('태그 · 장소 모아보기', () {
    test('태그: 표기만 달라도 같은 태그, 스토리를 넘나든다', () async {
      final trip = await newStory('제주');
      final a = await create(
        tags: ['#Jeju'],
        occurredAt: DateTime(2026, 10, 1),
      );
      final b = await create(
        storyId: trip.id,
        tags: ['jeju'],
        occurredAt: DateTime(2026, 10, 2),
      );
      await create(tags: ['busan']);

      expect(await idsIn(const EntryFilter.tag(' # JEJU ')), [b.id, a.id]);
    });

    test('장소: 앞뒤 공백을 다듬은 이름으로 찾고, 스토리를 넘나든다', () async {
      final trip = await newStory('제주');
      final a = await create(
        location: const EntryLocation(placeName: '애월읍'),
        occurredAt: DateTime(2026, 10, 1),
      );
      final b = await create(
        storyId: trip.id,
        location: const EntryLocation(placeName: '애월읍'),
        occurredAt: DateTime(2026, 10, 2),
      );
      await create(location: const EntryLocation(placeName: '한림읍'));

      expect(await idsIn(const EntryFilter.place(' 애월읍 ')), [b.id, a.id]);
    });
  });

  group('스토리 제목(watchStoryMatches)', () {
    Future<List<(String, int)>> matches(String q) async => [
      for (final m
          in await h.repository.watchStoryMatches(q, dailyTitle: '일상').first)
        (m.story.title, m.count),
    ];

    test('포함 일치 · 대소문자 무시 · 휴지통 제외 개수', () async {
      final trip = await newStory('Jeju Trip');
      await newStory('Busan');
      await create(storyId: trip.id);
      final trashed = await create(storyId: trip.id);
      okValue(await h.repository.trashEntry(trashed.id));

      expect(await matches('jeju'), [('Jeju Trip', 1)]);
      expect(await matches('TRIP'), [('Jeju Trip', 1)]);
      expect(await matches('없는 제목'), isEmpty);
    });

    test('기본 스토리는 dailyTitle 로 찾는다', () async {
      await create();
      await newStory('일상 밖');

      final found = await h.repository
          .watchStoryMatches('일상', dailyTitle: '일상')
          .first;

      expect([
        for (final m in found) (m.story.id, m.count),
      ], containsAll([(Story.dailyId, 1)]));
      expect(await matches('daily'), isEmpty);
    });

    test('기본 스토리 이름을 바꿨으면 그 이름으로 찾는다', () async {
      final daily = (await h.repository.watchStories().first).single;
      okValue(await h.repository.updateStory(daily.copyWith(title: '하루하루')));

      expect(await matches('하루'), [('하루하루', 0)]);
      expect(await matches('일상'), isEmpty);
    });

    test('정렬은 StoryOrder: 열린 것(최근 기록 순) → 보관함', () async {
      final older = await newStory('제주 1차');
      final closed = await newStory('제주 0차', endedAt: DateTime(2026, 2, 1));
      final newer = await newStory('제주 2차');
      await create(storyId: newer.id);
      h.clock.advance(const Duration(minutes: 1));
      await create(storyId: older.id);

      final found = await h.repository
          .watchStoryMatches('제주', dailyTitle: '일상')
          .first;

      expect(
        [for (final m in found) m.story.id],
        [older.id, newer.id, closed.id],
      );
    });

    test('기록 추가 · 휴지통에 개수가 다시 계산되어 흐른다', () async {
      final trip = await newStory('제주');
      final events = await recordEvents(
        h.repository.watchStoryMatches('제주', dailyTitle: '일상'),
      );
      expect(events.last.single.count, 0);

      final e = await create(storyId: trip.id);
      await pumpEventQueue();
      expect(events.last.single.count, 1);

      okValue(await h.repository.trashEntry(e.id));
      await pumpEventQueue();
      expect(events.last.single.count, 0);
    });
  });
}
