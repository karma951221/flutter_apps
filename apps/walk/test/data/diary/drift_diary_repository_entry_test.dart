import 'package:core/core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/diary/database/diary_database.dart';
import 'package:walk/domain/diary/diary_failure.dart';
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

  Future<Story> storyOf(String id) async =>
      (await h.repository.watchStories().first).singleWhere((s) => s.id == id);

  Future<Story> newStory(String title, {DateTime? endedAt}) async => okValue(
    await h.repository.createStory(
      title: title,
      startedAt: DateTime(2026, 1, 1),
      endedAt: endedAt,
    ),
  );

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

  group('createEntry', () {
    test('미디어 3개를 순서대로 저장하고 다시 읽는다', () async {
      final media = [photoMedia('m3'), videoMedia('m1'), photoMedia('m2')];
      final created = okValue(
        await h.repository.createEntry(entryDraft(media: media)),
      );

      final loaded = okValue(await h.repository.entry(created.id));
      expect(loaded.media, media);
      expect(created.media, media);
    });

    test('id · createdAt = updatedAt = now 를 채운다', () async {
      h.clock.value = DateTime(2026, 10, 10, 12);
      final entry = await create(occurredAt: DateTime(2026, 10, 9, 8));

      expect(entry.id, isNotEmpty);
      expect(entry.storyId, Story.dailyId);
      expect(entry.occurredAt, DateTime(2026, 10, 9, 8));
      expect(entry.createdAt, DateTime(2026, 10, 10, 12));
      expect(entry.updatedAt, DateTime(2026, 10, 10, 12));
      expect(entry.deletedAt, isNull);
    });

    test('태그는 입력 순으로 저장되고, 같은 태그는 기존 행을 재사용한다', () async {
      final first = await create(tags: ['jeju', 'food']);
      final second = await create(tags: ['food', 'jeju']);

      expect(first.tags, ['jeju', 'food']);
      expect(second.tags, ['food', 'jeju']);
      expect(await h.db.select(h.db.tags).get(), hasLength(2));
      expect(await h.db.select(h.db.entryTags).get(), hasLength(4));
    });

    test('표기만 다른 태그는 하나로 정규화된다', () async {
      final entry = await create(tags: ['#Jeju', 'jeju', ' 제 주 ']);

      expect(entry.tags, ['jeju', '제주']);
      expect(await h.db.select(h.db.tags).get(), hasLength(2));
    });

    test('같은 장소 이름 두 기록 → places 행 1, 좌표는 기록마다', () async {
      final a = await create(
        location: const EntryLocation(
          placeName: '애월읍',
          lat: 33.46,
          lng: 126.31,
        ),
      );
      final b = await create(
        location: const EntryLocation(
          placeName: '애월읍',
          lat: 33.47,
          lng: 126.32,
        ),
      );

      expect(await h.db.select(h.db.places).get(), hasLength(1));
      expect(
        okValue(await h.repository.entry(a.id)).location,
        const EntryLocation(placeName: '애월읍', lat: 33.46, lng: 126.31),
      );
      expect(b.location?.lat, 33.47);
    });

    test('좌표만 있는 위치도 왕복한다', () async {
      final entry = await create(
        location: const EntryLocation(lat: 33.4, lng: 126.5),
      );

      expect(
        okValue(await h.repository.entry(entry.id)).location,
        const EntryLocation(lat: 33.4, lng: 126.5),
      );
      expect(await h.db.select(h.db.places).get(), isEmpty);
    });

    test('위치가 없으면 location 은 null', () async {
      final entry = await create();
      expect(okValue(await h.repository.entry(entry.id)).location, isNull);
    });

    test('저장하면 그 스토리의 lastPostedAt = now', () async {
      final jeju = await newStory('제주');
      h.clock.value = DateTime(2026, 10, 10, 15);

      await create(storyId: jeju.id);

      expect((await storyOf(jeju.id)).lastPostedAt, DateTime(2026, 10, 10, 15));
      expect((await storyOf(Story.dailyId)).lastPostedAt, isNull);
    });

    test('닫힌 스토리에 새 기록은 storyClosed', () async {
      final closed = await newStory('지난 여행', endedAt: DateTime(2026, 2, 1));

      final result = await h.repository.createEntry(
        entryDraft(storyId: closed.id),
      );

      expect(errFailure(result), isDiaryFailure(DiaryFailure.storyClosed.name));
      expect(await h.db.select(h.db.entries).get(), isEmpty);
    });

    test('없는 스토리에 새 기록은 notFound', () async {
      final result = await h.repository.createEntry(
        entryDraft(storyId: 'ghost'),
      );
      expect(errFailure(result), isA<NotFoundFailure>());
    });

    test('규칙 위반(빈 기록)은 저장하지 않는다', () async {
      final result = await h.repository.createEntry(entryDraft(body: '  '));

      expect(errFailure(result), isDiaryFailure(DiaryFailure.emptyEntry.name));
      expect(await h.db.select(h.db.entries).get(), isEmpty);
    });

    test('이모지 · 1만 자 본문이 그대로 왕복한다', () async {
      final body = '제주🍊👨‍👩‍👧 한글ㄱ${'가나다라마바사🙂' * 1250}';
      expect(body.length, greaterThanOrEqualTo(10000));

      final entry = await create(body: body);

      expect(okValue(await h.repository.entry(entry.id)).body, body);
    });
  });

  group('updateEntry', () {
    test('updatedAt 만 바뀌고 createdAt 은 그대로', () async {
      final entry = await create(body: '처음');
      h.clock.advance(const Duration(hours: 1));

      final updated = okValue(
        await h.repository.updateEntry(entry.id, entryDraft(body: '고침')),
      );

      expect(updated.id, entry.id);
      expect(updated.body, '고침');
      expect(updated.createdAt, entry.createdAt);
      expect(updated.updatedAt, entry.createdAt.add(const Duration(hours: 1)));
      expect(okValue(await h.repository.entry(entry.id)), updated);
    });

    test('미디어 · 태그 · 장소를 draft 대로 바꾼다(같은 미디어 id 유지)', () async {
      final entry = okValue(
        await h.repository.createEntry(
          entryDraft(
            media: [photoMedia('m1'), photoMedia('m2')],
            tags: ['jeju'],
            location: const EntryLocation(placeName: '애월읍'),
          ),
        ),
      );

      final updated = okValue(
        await h.repository.updateEntry(
          entry.id,
          entryDraft(
            media: [photoMedia('m2'), videoMedia('m3')],
            tags: ['busan'],
            location: const EntryLocation(placeName: '해운대'),
          ),
        ),
      );

      expect(updated.media.map((m) => m.id), ['m2', 'm3']);
      expect(updated.tags, ['busan']);
      expect(updated.location?.placeName, '해운대');
      expect(await h.db.select(h.db.media).get(), hasLength(2));
      expect(await h.db.select(h.db.entryTags).get(), hasLength(1));
    });

    test('위치를 끄면 장소 · 좌표가 모두 비워진다', () async {
      final entry = await create(
        location: const EntryLocation(placeName: '애월읍', lat: 1, lng: 2),
      );

      final updated = okValue(
        await h.repository.updateEntry(entry.id, entryDraft()),
      );

      expect(updated.location, isNull);
      final row = await (h.db.select(
        h.db.entries,
      )..where((e) => e.id.equals(entry.id))).getSingle();
      expect([row.placeId, row.lat, row.lng], [null, null, null]);
    });

    test('occurredAt 을 과거로 바꾸면 watchEntries(story) 순서가 바뀐다', () async {
      final older = await create(body: 'a', occurredAt: DateTime(2026, 10, 9));
      final newer = await create(body: 'b', occurredAt: DateTime(2026, 10, 10));
      final filter = EntryFilter.story(Story.dailyId);
      expect((await h.repository.watchEntries(filter).first).map((e) => e.id), [
        newer.id,
        older.id,
      ]);

      okValue(
        await h.repository.updateEntry(
          newer.id,
          entryDraft(body: 'b', occurredAt: DateTime(2026, 10, 8)),
        ),
      );

      expect((await h.repository.watchEntries(filter).first).map((e) => e.id), [
        older.id,
        newer.id,
      ]);
    });

    test('스토리를 옮기면 새 스토리 lastPostedAt = now', () async {
      final jeju = await newStory('제주');
      final entry = await create();
      h.clock.advance(const Duration(hours: 2));

      final moved = okValue(
        await h.repository.updateEntry(entry.id, entryDraft(storyId: jeju.id)),
      );

      expect(moved.storyId, jeju.id);
      expect((await storyOf(jeju.id)).lastPostedAt, h.clock.now());
    });

    test('닫힌 스토리로도 옮길 수 있다(R23 — 지난 여행 정리), 스토리는 닫힌 채', () async {
      final closed = await newStory('지난 여행', endedAt: DateTime(2026, 2, 1));
      final entry = await create();

      final moved = okValue(
        await h.repository.updateEntry(
          entry.id,
          entryDraft(storyId: closed.id),
        ),
      );

      expect(moved.storyId, closed.id);
      final story = await storyOf(closed.id);
      expect(story.status, StoryStatus.closed);
      expect(story.endedAt, DateTime(2026, 2, 1));
    });

    test('닫힌 스토리의 기존 기록은 스토리를 그대로 두면 고칠 수 있다', () async {
      final jeju = await newStory('제주');
      final entry = await create(storyId: jeju.id, body: '처음');
      okValue(
        await h.repository.updateStory(
          okValue(jeju.close(DateTime(2026, 2, 1))),
        ),
      );

      final updated = okValue(
        await h.repository.updateEntry(
          entry.id,
          entryDraft(storyId: jeju.id, body: '고침'),
        ),
      );

      expect(updated.body, '고침');
    });

    test('없는 id 는 notFound', () async {
      final result = await h.repository.updateEntry('ghost', entryDraft());
      expect(errFailure(result), isA<NotFoundFailure>());
    });

    test('휴지통 기록은 복원 전까지 고칠 수 없다(notFound)', () async {
      final entry = await create(body: '원본');
      await h.trashDirectly(entry.id);

      final result = await h.repository.updateEntry(
        entry.id,
        entryDraft(body: '고침'),
      );

      expect(errFailure(result), isA<NotFoundFailure>());
      final stored = okValue(await h.repository.entry(entry.id));
      expect(stored.body, '원본');
      expect(stored.updatedAt, entry.updatedAt);
    });
  });

  group('moveEntries', () {
    test('여러 기록을 옮기고 새 스토리 lastPostedAt = now', () async {
      final jeju = await newStory('제주');
      final a = await create();
      final b = await create();
      final stay = await create();
      h.clock.advance(const Duration(hours: 1));

      okValue(await h.repository.moveEntries([a.id, b.id], jeju.id));

      final inJeju = await h.repository
          .watchEntries(EntryFilter.story(jeju.id))
          .first;
      expect(inJeju.map((e) => e.id).toSet(), {a.id, b.id});
      expect(okValue(await h.repository.entry(stay.id)).storyId, Story.dailyId);
      expect((await storyOf(jeju.id)).lastPostedAt, h.clock.now());
    });

    test('닫힌 스토리로도 옮긴다(R23), 스토리는 닫힌 채 같은 종료일', () async {
      final closed = await newStory('지난 여행', endedAt: DateTime(2026, 2, 1));
      final a = await create();

      okValue(await h.repository.moveEntries([a.id], closed.id));

      expect(okValue(await h.repository.entry(a.id)).storyId, closed.id);
      final story = await storyOf(closed.id);
      expect(story.status, StoryStatus.closed);
      expect(story.endedAt, DateTime(2026, 2, 1));
    });

    test('없는 스토리로는 notFound', () async {
      final a = await create();
      expect(
        errFailure(await h.repository.moveEntries([a.id], 'ghost')),
        isA<NotFoundFailure>(),
      );
    });

    test('휴지통 기록은 옮기지 않는다', () async {
      final jeju = await newStory('제주');
      final live = await create();
      final trashed = await create();
      await h.trashDirectly(trashed.id);

      okValue(await h.repository.moveEntries([live.id, trashed.id], jeju.id));

      expect(okValue(await h.repository.entry(live.id)).storyId, jeju.id);
      expect(
        okValue(await h.repository.entry(trashed.id)).storyId,
        Story.dailyId,
      );
    });

    test('실제로 옮긴 기록이 없으면 lastPostedAt 을 바꾸지 않는다', () async {
      final jeju = await newStory('제주');
      final trashed = await create();
      await h.trashDirectly(trashed.id);
      h.clock.advance(const Duration(hours: 1));

      okValue(await h.repository.moveEntries([trashed.id, 'ghost'], jeju.id));
      okValue(await h.repository.moveEntries([], jeju.id));

      expect((await storyOf(jeju.id)).lastPostedAt, isNull);
    });
  });

  group('트랜잭션 실패', () {
    test('도중에 실패하면 기록 · 태그 · 장소 행이 남지 않고 lastPostedAt 도 그대로', () async {
      final first = okValue(
        await h.repository.createEntry(entryDraft(media: [photoMedia('m1')])),
      );
      final postedBefore = (await storyOf(Story.dailyId)).lastPostedAt;
      h.clock.advance(const Duration(hours: 1));

      // 이미 다른 기록이 가진 미디어 id → media PK 위반으로 트랜잭션 중간에 실패.
      final result = await h.repository.createEntry(
        entryDraft(
          body: '실패할 기록',
          media: [photoMedia('m1')],
          tags: ['새태그'],
          location: const EntryLocation(placeName: '새장소'),
        ),
      );

      expect(errFailure(result), isA<UnknownFailure>());
      final entries = await h.db.select(h.db.entries).get();
      expect(entries.map((e) => e.id), [first.id]);
      expect(await h.db.select(h.db.tags).get(), isEmpty);
      expect(await h.db.select(h.db.entryTags).get(), isEmpty);
      expect(await h.db.select(h.db.places).get(), isEmpty);
      expect((await storyOf(Story.dailyId)).lastPostedAt, postedBefore);
      expect((await h.db.select(h.db.media).get()).map((m) => m.entryId), [
        first.id,
      ]);
    });
  });

  group('entry', () {
    test('없는 id 는 notFound', () async {
      expect(
        errFailure(await h.repository.entry('ghost')),
        isA<NotFoundFailure>(),
      );
    });

    test('휴지통 기록도 돌려준다', () async {
      final entry = await create();
      await h.trashDirectly(entry.id);

      expect(okValue(await h.repository.entry(entry.id)).isTrashed, isTrue);
    });
  });

  group('watchEntries', () {
    test('occurredAt 내림차순, 같으면 createdAt 내림차순', () async {
      final same = DateTime(2026, 10, 9, 12);
      final first = await create(occurredAt: same);
      h.clock.advance(const Duration(minutes: 1));
      final second = await create(occurredAt: same);
      final latest = await create(occurredAt: DateTime(2026, 10, 10));

      final list = await h.repository
          .watchEntries(const EntryFilter.all())
          .first;

      expect(list.map((e) => e.id), [latest.id, second.id, first.id]);
    });

    test('저장 · 수정 뒤 새 값을 내보낸다', () async {
      final stream = h.repository.watchEntries(const EntryFilter.all());
      final bodies = <List<String>>[];
      final sub = stream.listen((l) => bodies.add([for (final e in l) e.body]));
      addTearDown(sub.cancel);
      await pumpEventQueue();

      final entry = await create(body: '처음');
      await pumpEventQueue();
      okValue(await h.repository.updateEntry(entry.id, entryDraft(body: '고침')));
      await pumpEventQueue();

      expect(bodies.first, isEmpty);
      expect(bodies[1], ['처음']);
      expect(bodies.last, ['고침']);
    });

    test('entries 밖의 테이블(태그)만 바뀌어도 새 값을 내보낸다', () async {
      final entry = await create();
      final stream = h.repository.watchEntries(const EntryFilter.all());
      final expectation = expectLater(
        stream.map((l) => l.single.tags),
        emitsInOrder([
          isEmpty,
          ['busan'],
        ]),
      );
      await pumpEventQueue();

      // entries 행은 건드리지 않고 tags · entry_tags 만 쓴다.
      await h.db
          .into(h.db.tags)
          .insert(
            TagsCompanion.insert(id: 't1', name: 'busan', createdAt: diaryT0),
          );
      await h.db
          .into(h.db.entryTags)
          .insert(EntryTagsCompanion.insert(entryId: entry.id, tagId: 't1'));
      await expectation;
    });

    test('media 만 바뀌어도 새 값을 내보낸다', () async {
      final entry = await create();
      final stream = h.repository.watchEntries(const EntryFilter.all());
      final expectation = expectLater(
        stream.map((l) => [for (final m in l.single.media) m.id]),
        emitsInOrder([
          isEmpty,
          ['m1'],
        ]),
      );
      await pumpEventQueue();

      // entries 행은 건드리지 않고 media 만 쓴다.
      await h.db
          .into(h.db.media)
          .insert(
            MediaCompanion.insert(
              id: 'm1',
              entryId: entry.id,
              kind: MediaKind.photo,
              path: 'media/m1.jpg',
              sortOrder: 0,
              width: 10,
              height: 10,
              bytes: 1,
            ),
          );
      await expectation;
    });

    test('places 만 바뀌어도 새 값을 내보낸다', () async {
      await create(location: const EntryLocation(placeName: '애월읍'));
      final stream = h.repository.watchEntries(const EntryFilter.all());
      final expectation = expectLater(
        stream.map((l) => l.single.location?.placeName),
        emitsInOrder(['애월읍', '애월리']),
      );
      await pumpEventQueue();

      // entries 행은 건드리지 않고 places 이름만 바꾼다.
      await h.db
          .update(h.db.places)
          .write(const PlacesCompanion(name: Value('애월리')));
      await expectation;
    });

    test('휴지통 기록은 모든 필터에서 빠진다', () async {
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
      await h.trashDirectly(trashed.id);

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
    });

    test('tag 필터: 정규화된 이름으로, 스토리를 넘나든다', () async {
      final jeju = await newStory('제주');
      final a = await create(tags: ['jeju'], occurredAt: DateTime(2026, 10, 1));
      final b = await create(
        storyId: jeju.id,
        tags: ['jeju', 'food'],
        occurredAt: DateTime(2026, 10, 2),
      );
      await create(tags: ['food']);

      final list = await h.repository
          .watchEntries(const EntryFilter.tag('#Jeju'))
          .first;

      expect(list.map((e) => e.id), [b.id, a.id]);
    });

    test('place 필터: 장소 이름이 같은 기록', () async {
      final a = await create(location: const EntryLocation(placeName: '애월읍'));
      await create(location: const EntryLocation(placeName: '해운대'));
      await create();

      final list = await h.repository
          .watchEntries(const EntryFilter.place('애월읍'))
          .first;

      expect(list.map((e) => e.id), [a.id]);
    });

    test('body 필터: 부분 일치, % · _ 는 글자 그대로', () async {
      final percent = await create(body: '할인 50% 받음');
      await create(body: '할인 500 받음');
      final under = await create(body: 'a_b');
      await create(body: 'axb');

      Future<List<String>> search(String q) async => [
        for (final e
            in await h.repository.watchEntries(EntryFilter.body(q)).first)
          e.id,
      ];

      expect(await search('50%'), [percent.id]);
      expect(await search('a_b'), [under.id]);
      expect(await search('받음'), hasLength(2));
    });
  });
}
