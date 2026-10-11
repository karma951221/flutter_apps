import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';

import '../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;

  setUp(() => h = DiaryHarness());
  tearDown(() => h.close());

  Future<DiaryEntry> create({
    String storyId = Story.dailyId,
    String body = '본문',
    List<EntryMedia> media = const [],
    List<String> tags = const [],
    EntryLocation? location,
  }) async => okValue(
    await h.repository.createEntry(
      entryDraft(
        storyId: storyId,
        body: body,
        media: media,
        tags: tags,
        location: location,
      ),
    ),
  );

  Future<List<String>> trashIds() async => [
    for (final e in await h.repository.watchTrash().first) e.id,
  ];

  Future<List<String>> mediaOwners() async => [
    for (final m in await h.db.select(h.db.media).get()) m.entryId,
  ];

  Future<Set<String>> tagNames() async => {
    for (final t in await h.db.select(h.db.tags).get()) t.name,
  };

  Future<Set<String>> placeNames() async => {
    for (final p in await h.db.select(h.db.places).get()) p.name,
  };

  group('trashEntry', () {
    test('deletedAt = now 만 채우고 행 · 미디어 행 · updatedAt 은 그대로', () async {
      final entry = await create(
        media: [photoMedia('p1'), videoMedia('v1')],
        tags: ['jeju'],
      );
      h.clock.advance(const Duration(hours: 2));

      okValue(await h.repository.trashEntry(entry.id));

      final stored = okValue(await h.repository.entry(entry.id));
      expect(stored.deletedAt, h.clock.now());
      expect(stored.updatedAt, entry.updatedAt);
      expect(stored.media, entry.media);
      expect(stored.tags, entry.tags);
      expect(await mediaOwners(), [entry.id, entry.id]);
      expect(await h.db.select(h.db.entryTags).get(), hasLength(1));
    });

    test('모든 목록 · 검색에서 빠지고 휴지통에 나타난다', () async {
      final kept = await create(
        body: '귤 먹음',
        tags: ['jeju'],
        location: const EntryLocation(placeName: '애월읍'),
      );
      final trashed = await create(
        body: '귤 또 먹음',
        tags: ['jeju'],
        location: const EntryLocation(placeName: '애월읍'),
      );

      okValue(await h.repository.trashEntry(trashed.id));

      for (final filter in [
        const EntryFilter.all(),
        EntryFilter.story(Story.dailyId),
        const EntryFilter.tag('jeju'),
        const EntryFilter.place('애월읍'),
        const EntryFilter.body('귤'),
      ]) {
        final ids = (await h.repository.watchEntries(filter).first).map(
          (e) => e.id,
        );
        expect(ids, [kept.id], reason: '$filter');
      }
      expect(await trashIds(), [trashed.id]);
    });

    test('watchTrash 는 deletedAt 내림차순', () async {
      final a = await create();
      final b = await create();
      final c = await create();
      okValue(await h.repository.trashEntry(b.id));
      h.clock.advance(const Duration(minutes: 1));
      okValue(await h.repository.trashEntry(a.id));
      h.clock.advance(const Duration(minutes: 1));
      okValue(await h.repository.trashEntry(c.id));

      expect(await trashIds(), [c.id, a.id, b.id]);
    });

    test('이미 휴지통이면 처음 deletedAt 을 유지한다', () async {
      final entry = await create();
      okValue(await h.repository.trashEntry(entry.id));
      final first = h.clock.now();
      h.clock.advance(const Duration(days: 1));

      okValue(await h.repository.trashEntry(entry.id));

      expect(okValue(await h.repository.entry(entry.id)).deletedAt, first);
    });

    test('없는 id 는 notFound', () async {
      expect(
        errFailure(await h.repository.trashEntry('ghost')),
        isA<NotFoundFailure>(),
      );
    });
  });

  group('purgeEntries', () {
    test('기록 · 미디어 · 태그 연결 행을 지우고 원본 · 썸네일 경로를 돌려준다', () async {
      final entry = await create(
        media: [photoMedia('p1'), videoMedia('v1')],
        tags: ['jeju', 'food'],
      );
      okValue(await h.repository.trashEntry(entry.id));

      final paths = okValue(await h.repository.purgeEntries([entry.id]));

      expect(
        paths,
        unorderedEquals(['media/p1.jpg', 'media/v1.mp4', 'media/v1.thumb.jpg']),
      );
      expect(await h.db.select(h.db.entries).get(), isEmpty);
      expect(await h.db.select(h.db.media).get(), isEmpty);
      expect(await h.db.select(h.db.entryTags).get(), isEmpty);
      expect(await trashIds(), isEmpty);
      expect(
        errFailure(await h.repository.entry(entry.id)),
        isA<NotFoundFailure>(),
      );
    });

    test('다른 기록의 미디어 · 공유 태그 · 장소는 남고, 안 쓰는 태그 · 장소만 정리한다', () async {
      final other = await create(
        media: [photoMedia('keep')],
        tags: ['jeju'],
        location: const EntryLocation(placeName: '애월읍'),
      );
      final gone = await create(
        media: [photoMedia('gone')],
        tags: ['jeju', 'solo'],
        location: const EntryLocation(placeName: '성산'),
      );
      okValue(await h.repository.trashEntry(gone.id));

      okValue(await h.repository.purgeEntries([gone.id]));

      expect(await mediaOwners(), [other.id]);
      expect(await tagNames(), {'jeju'});
      expect(await placeNames(), {'애월읍'});
      expect(okValue(await h.repository.entry(other.id)), other);
    });

    test('휴지통에 남은 기록이 쓰는 태그 · 장소는 지우지 않는다(복원 시 같은 행)', () async {
      final waiting = await create(
        tags: ['jeju'],
        location: const EntryLocation(placeName: '애월읍'),
      );
      final gone = await create(
        tags: ['jeju'],
        location: const EntryLocation(placeName: '애월읍'),
      );
      okValue(await h.repository.trashEntry(waiting.id));
      okValue(await h.repository.trashEntry(gone.id));

      okValue(await h.repository.purgeEntries([gone.id]));

      expect(await tagNames(), {'jeju'});
      expect(await placeNames(), {'애월읍'});
    });

    test('지워진 미디어를 표지로 둔 스토리는 coverMediaId = null', () async {
      final jeju = okValue(
        await h.repository.createStory(
          title: '제주',
          startedAt: DateTime(2026, 1, 1),
        ),
      );
      final entry = await create(
        storyId: jeju.id,
        media: [photoMedia('cover')],
      );
      final kept = await create(media: [photoMedia('daily-cover')]);
      okValue(
        await h.repository.updateStory(jeju.copyWith(coverMediaId: 'cover')),
      );
      final daily = (await h.repository.watchStories().first).singleWhere(
        (s) => s.isDefault,
      );
      okValue(
        await h.repository.updateStory(
          daily.copyWith(coverMediaId: 'daily-cover'),
        ),
      );
      okValue(await h.repository.trashEntry(entry.id));

      okValue(await h.repository.purgeEntries([entry.id]));

      final stories = await h.repository.watchStories().first;
      expect(stories.singleWhere((s) => s.id == jeju.id).coverMediaId, isNull);
      expect(
        stories.singleWhere((s) => s.isDefault).coverMediaId,
        kept.media.single.id,
      );
    });

    test('없는 id 는 건너뛰고, 휴지통에 없는 기록은 지우지 않는다', () async {
      final live = await create(media: [photoMedia('live')]);
      final trashed = await create(media: [photoMedia('trashed')]);
      okValue(await h.repository.trashEntry(trashed.id));

      final paths = okValue(
        await h.repository.purgeEntries(['ghost', live.id, trashed.id]),
      );

      expect(paths, ['media/trashed.jpg']);
      expect(okValue(await h.repository.entry(live.id)), live);
      expect(await mediaOwners(), [live.id]);
    });

    test('트랜잭션 중간에 실패하면 아무것도 바뀌지 않고 Err', () async {
      final jeju = okValue(
        await h.repository.createStory(
          title: '제주',
          startedAt: DateTime(2026, 1, 1),
        ),
      );
      final entry = await create(
        storyId: jeju.id,
        media: [photoMedia('cover')],
        tags: ['solo'],
        location: const EntryLocation(placeName: '성산'),
      );
      okValue(
        await h.repository.updateStory(jeju.copyWith(coverMediaId: 'cover')),
      );
      okValue(await h.repository.trashEntry(entry.id));
      // 표지 정리 뒤 entries 삭제에서 실패하게 만든다.
      await h.db.customStatement(
        'CREATE TRIGGER fail_purge BEFORE DELETE ON entries '
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );

      final result = await h.repository.purgeEntries([entry.id]);

      expect(errFailure(result), isA<UnknownFailure>());
      expect(okValue(await h.repository.entry(entry.id)), isNotNull);
      expect(await mediaOwners(), [entry.id]);
      expect(await h.db.select(h.db.entryTags).get(), hasLength(1));
      expect(await tagNames(), {'solo'});
      expect(await placeNames(), {'성산'});
      final stories = await h.repository.watchStories().first;
      expect(stories.singleWhere((s) => s.id == jeju.id).coverMediaId, 'cover');
    });

    test('DB 가 닫혀 있으면 Err, 경로를 돌려주지 않는다', () async {
      final entry = await create(media: [photoMedia('p1')]);
      okValue(await h.repository.trashEntry(entry.id));
      await h.db.close();

      expect(
        errFailure(await h.repository.purgeEntries([entry.id])),
        isA<UnknownFailure>(),
      );
    });
  });

  group('purgeAllTrash', () {
    test('휴지통 기록을 모두 지우고 살아 있는 기록은 남긴다', () async {
      final live = await create(media: [photoMedia('live')]);
      final a = await create(media: [photoMedia('a')]);
      final b = await create(media: [videoMedia('b')]);
      final c = await create();
      for (final e in [a, b, c]) {
        okValue(await h.repository.trashEntry(e.id));
      }

      final paths = okValue(await h.repository.purgeAllTrash());

      expect(
        paths,
        unorderedEquals(['media/a.jpg', 'media/b.mp4', 'media/b.thumb.jpg']),
      );
      expect(await trashIds(), isEmpty);
      expect(
        [for (final e in await h.db.select(h.db.entries).get()) e.id],
        [live.id],
      );
      expect(await mediaOwners(), [live.id]);
    });

    test('휴지통이 비어 있으면 빈 목록', () async {
      await create(media: [photoMedia('live')]);
      expect(okValue(await h.repository.purgeAllTrash()), isEmpty);
      expect(await mediaOwners(), hasLength(1));
    });
  });

  group('purgeTrashedBefore', () {
    test('deletedAt <= 기준(같은 시각 포함)만 지운다', () async {
      final older = await create(media: [photoMedia('older')]);
      final atCutoff = await create(media: [photoMedia('cutoff')]);
      final after = await create(media: [photoMedia('after')]);
      final live = await create();

      okValue(await h.repository.trashEntry(older.id));
      h.clock.advance(const Duration(days: 1));
      final cutoff = h.clock.now();
      okValue(await h.repository.trashEntry(atCutoff.id));
      h.clock.advance(const Duration(milliseconds: 1));
      okValue(await h.repository.trashEntry(after.id));

      final paths = okValue(await h.repository.purgeTrashedBefore(cutoff));

      expect(paths, unorderedEquals(['media/older.jpg', 'media/cutoff.jpg']));
      expect(await trashIds(), [after.id]);
      expect(okValue(await h.repository.entry(live.id)).isTrashed, isFalse);
    });
  });

  group('allMediaPaths', () {
    test('휴지통 기록을 포함한 모든 원본 · 썸네일 경로', () async {
      await create(media: [photoMedia('p1')]);
      final trashed = await create(media: [videoMedia('v1')]);
      okValue(await h.repository.trashEntry(trashed.id));

      expect(await h.repository.allMediaPaths(), {
        'media/p1.jpg',
        'media/v1.mp4',
        'media/v1.thumb.jpg',
      });
    });
  });
}
