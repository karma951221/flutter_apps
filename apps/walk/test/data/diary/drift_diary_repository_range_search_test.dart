import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';

import '../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;

  setUp(() => h = DiaryHarness());
  tearDown(() => h.close());

  Future<String> create({
    required DateTime at,
    String body = '본문',
    String storyId = 'daily',
    List<String> tags = const [],
    String? place,
  }) async => okValue(
    await h.repository.createEntry(
      entryDraft(
        storyId: storyId,
        body: body,
        occurredAt: at,
        tags: tags,
        location: place == null ? null : EntryLocation(placeName: place),
      ),
    ),
  ).id;

  final from = DateTime(2026, 10, 1);
  final to = DateTime(2026, 10, 9, 23, 59);

  Future<List<String>> bodies({
    String? query,
    String? tag,
    String? place,
    String? storyId,
    int limit = 50,
  }) async => [
    for (final e in await h.repository.searchEntries(
      from: from,
      to: to,
      query: query,
      tag: tag,
      place: place,
      storyId: storyId,
      limit: limit,
    ))
      e.body,
  ];

  group('searchEntries', () {
    test('여러 스토리의 기록을 기간으로 찾고 오래된 순으로 준다', () async {
      final trip = okValue(
        await h.repository.createStory(
          title: '여행',
          startedAt: DateTime(2026, 10, 1),
        ),
      );
      await create(at: DateTime(2026, 10, 5), body: 'c');
      await create(at: DateTime(2026, 10, 2), body: 'a', storyId: trip.id);
      await create(at: DateTime(2026, 10, 3), body: 'b');
      await create(at: DateTime(2026, 9, 30), body: '범위 밖 전');
      await create(at: DateTime(2026, 10, 9, 23, 59, 30), body: '범위 밖 후');

      final result = await h.repository.searchEntries(from: from, to: to);

      expect([for (final e in result) e.body], ['a', 'b', 'c']);
    });

    test('양 끝을 포함하고 미디어 · 태그 · 장소를 채운다', () async {
      await create(at: from, body: '시작', tags: ['제주'], place: '성산');
      await create(at: to, body: '끝');

      final result = await h.repository.searchEntries(from: from, to: to);

      expect([for (final e in result) e.body], ['시작', '끝']);
      expect(result.first.tags, ['제주']);
      expect(result.first.location?.placeName, '성산');
    });

    test('휴지통 기록은 빠진다', () async {
      await create(at: DateTime(2026, 10, 2), body: '살아있음');
      final id = await create(at: DateTime(2026, 10, 3), body: '휴지통');
      await h.trashDirectly(id);

      expect(await bodies(), ['살아있음']);
    });

    test('query · tag · place · storyId 를 각각 걸러낸다', () async {
      final trip = okValue(
        await h.repository.createStory(
          title: '여행',
          startedAt: DateTime(2026, 10, 1),
        ),
      );
      await create(at: DateTime(2026, 10, 2), body: 'Hello 100%');
      await create(at: DateTime(2026, 10, 3), body: '태그글', tags: ['제주']);
      await create(at: DateTime(2026, 10, 4), body: '장소글', place: '성산');
      await create(at: DateTime(2026, 10, 5), body: '스토리글', storyId: trip.id);

      expect(await bodies(query: 'hello'), ['Hello 100%']);
      expect(await bodies(query: '100%'), ['Hello 100%']);
      expect(await bodies(tag: '#제주'), ['태그글']);
      expect(await bodies(place: ' 성산 '), ['장소글']);
      expect(await bodies(storyId: trip.id), ['스토리글']);
    });

    test('limit 을 넘지 않는다', () async {
      for (var d = 1; d <= 5; d++) {
        await create(at: DateTime(2026, 10, d), body: 'e$d');
      }

      expect(await bodies(limit: 3), ['e1', 'e2', 'e3']);
    });

    test('limit 은 1 이상이어야 한다', () {
      expect(() => bodies(limit: 0), throwsAssertionError);
    });
  });

  group('locatedEntriesBetween', () {
    Future<String> located({
      required DateTime at,
      required String body,
      EntryLocation? location = const EntryLocation(lat: 37.5, lng: 127.0),
    }) async => okValue(
      await h.repository.createEntry(
        entryDraft(body: body, occurredAt: at, location: location),
      ),
    ).id;

    Future<List<String>> locatedBodies({int limit = 1000}) async => [
      for (final e in await h.repository.locatedEntriesBetween(
        from,
        to,
        limit: limit,
      ))
        e.body,
    ];

    test('좌표가 있는 기록만, 양 끝 포함 오래된 순', () async {
      await located(at: DateTime(2026, 10, 5), body: 'c');
      await located(at: from, body: 'a');
      await located(at: to, body: 'd');
      await located(at: DateTime(2026, 10, 3), body: 'b');
      await located(
        at: DateTime(2026, 10, 4),
        body: '이름만',
        location: const EntryLocation(placeName: '성산'),
      );
      await located(at: DateTime(2026, 10, 4), body: '위치 없음', location: null);
      await located(at: DateTime(2026, 9, 30), body: '범위 밖');

      expect(await locatedBodies(), ['a', 'b', 'c', 'd']);
    });

    test('휴지통 기록은 빠진다', () async {
      final trashed = await located(at: DateTime(2026, 10, 2), body: '버림');
      await located(at: DateTime(2026, 10, 3), body: '남김');
      okValue(await h.repository.trashEntry(trashed));

      expect(await locatedBodies(), ['남김']);
    });

    test('좌표 없는 기록이 많아도 limit 은 좌표 있는 기록에 쓴다', () async {
      // Dart 에서 거르면 앞의 좌표 없는 기록이 limit 을 먹는다.
      for (var i = 0; i < 5; i++) {
        await located(
          at: DateTime(2026, 10, 1, 10, i),
          body: '없음$i',
          location: null,
        );
      }
      await located(at: DateTime(2026, 10, 2), body: 'p1');
      await located(at: DateTime(2026, 10, 3), body: 'p2');
      await located(at: DateTime(2026, 10, 4), body: 'p3');

      expect(await locatedBodies(limit: 2), ['p1', 'p2']);
    });

    test('기본 limit 은 1000', () async {
      for (var i = 0; i < 1001; i++) {
        await located(
          at: DateTime(2026, 10, 2).add(Duration(minutes: i)),
          body: 'e$i',
        );
      }

      expect(
        await h.repository.locatedEntriesBetween(from, to),
        hasLength(1000),
      );
    });
  });
}
