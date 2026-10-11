import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';

import '../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;

  setUp(() => h = DiaryHarness());
  tearDown(() => h.close());

  Future<DiaryEntry> create({
    required DateTime occurredAt,
    List<String> tags = const [],
    String? place,
  }) async => okValue(
    await h.repository.createEntry(
      entryDraft(
        occurredAt: occurredAt,
        tags: tags,
        location: place == null ? null : EntryLocation(placeName: place),
      ),
    ),
  );

  Future<List<String>> tags({String query = '', int limit = 20}) async =>
      namedCounts(
        await h.repository.watchTagCounts(query: query, limit: limit).first,
      );

  Future<List<String>> places({String query = '', int limit = 20}) async =>
      namedCounts(
        await h.repository.watchPlaceCounts(query: query, limit: limit).first,
      );

  group('태그 추천', () {
    test("'제' → 제주(3) · 제천(1) 순, 포함 일치만", () async {
      for (var d = 1; d <= 3; d++) {
        await create(occurredAt: DateTime(2026, 10, d), tags: ['제주']);
      }
      await create(occurredAt: DateTime(2026, 10, 9), tags: ['제천']);
      await create(occurredAt: DateTime(2026, 10, 9), tags: ['부산']);
      await create(occurredAt: DateTime(2026, 10, 8), tags: ['서귀포제과']);

      expect(await tags(query: '제'), ['제주 3', '제천 1', '서귀포제과 1']);
      expect(await tags(query: '제주'), ['제주 3']);
    });

    test(
      '같은 count 는 lastUsedAt(쓰는 기록의 최대 occurredAt) 최신 먼저, 그다음 이름순',
      () async {
        await create(occurredAt: DateTime(2026, 10, 1), tags: ['old']);
        await create(occurredAt: DateTime(2026, 10, 5), tags: ['new']);
        await create(occurredAt: DateTime(2026, 10, 3), tags: ['mid', 'amid']);

        final counts = await h.repository.watchTagCounts().first;

        expect(namedCounts(counts), ['new 1', 'amid 1', 'mid 1', 'old 1']);
        expect(counts.first.lastUsedAt, DateTime(2026, 10, 5));
      },
    );

    test('lastUsedAt 은 휴지통이 아닌 기록 중 가장 늦은 occurredAt', () async {
      await create(occurredAt: DateTime(2026, 10, 1), tags: ['jeju']);
      final latest = await create(
        occurredAt: DateTime(2026, 10, 7),
        tags: ['jeju'],
      );
      await create(occurredAt: DateTime(2026, 10, 4), tags: ['jeju']);
      okValue(await h.repository.trashEntry(latest.id));

      final jeju = (await h.repository.watchTagCounts().first).single;

      expect((jeju.count, jeju.lastUsedAt), (2, DateTime(2026, 10, 4)));
    });

    test('빈 입력이면 상위 N 개', () async {
      for (var i = 0; i < 5; i++) {
        await create(
          occurredAt: DateTime(2026, 10, 1, i),
          tags: [for (var j = 0; j <= i; j++) 't$j'],
        );
      }

      expect(await tags(limit: 3), ['t0 5', 't1 4', 't2 3']);
      expect(await tags(), hasLength(5));
      expect(await tags(query: '  ', limit: 2), ['t0 5', 't1 4']);
      expect(await tags(query: '#', limit: 2), ['t0 5', 't1 4']);
    });

    test("'#JE' 입력은 정규화되어 jeju 와 매치한다", () async {
      await create(occurredAt: DateTime(2026, 10, 1), tags: ['jeju']);
      await create(occurredAt: DateTime(2026, 10, 1), tags: ['busan']);

      expect(await tags(query: '#JE'), ['jeju 1']);
      expect(await tags(query: ' j e '), ['jeju 1']);
    });

    test('Review Focus 2: #Jeju · jeju · " JE JU " 는 태그 행 하나 · 칩 하나', () async {
      await create(occurredAt: DateTime(2026, 10, 1), tags: ['#Jeju']);
      await create(occurredAt: DateTime(2026, 10, 2), tags: ['jeju']);
      await create(occurredAt: DateTime(2026, 10, 3), tags: [' JE JU ']);
      await create(occurredAt: DateTime(2026, 10, 4), tags: [' 제 주 ', '#제주']);

      expect(await h.db.select(h.db.tags).get(), hasLength(2));
      expect(await tags(), ['jeju 3', '제주 1']);
    });

    test('휴지통 제외 개수, 0 개면 숨김', () async {
      final a = await create(occurredAt: DateTime(2026, 10, 1), tags: ['jeju']);
      await create(occurredAt: DateTime(2026, 10, 2), tags: ['jeju']);
      final b = await create(occurredAt: DateTime(2026, 10, 3), tags: ['solo']);
      okValue(await h.repository.trashEntry(a.id));
      okValue(await h.repository.trashEntry(b.id));

      expect(await tags(), ['jeju 1']);
      expect(await tags(query: 'solo'), isEmpty);
    });

    test('30자를 넘는 입력은 어떤 태그와도 맞지 않는다', () async {
      await create(occurredAt: DateTime(2026, 10, 1), tags: ['jeju']);

      expect(await tags(query: 'j' * 31), isEmpty);
    });

    test('% · _ 는 글자 그대로', () async {
      await create(occurredAt: DateTime(2026, 10, 1), tags: ['a_b']);
      await create(occurredAt: DateTime(2026, 10, 1), tags: ['axb']);

      expect(await tags(query: '_'), ['a_b 1']);
      expect(await tags(query: '%'), isEmpty);
    });
  });

  group('장소 추천', () {
    test('포함 일치 · 개수 → 최근 사용 순 · 앞뒤 공백 무시', () async {
      await create(occurredAt: DateTime(2026, 10, 1), place: '애월읍');
      await create(occurredAt: DateTime(2026, 10, 2), place: '애월읍');
      await create(occurredAt: DateTime(2026, 10, 3), place: '애월 카페');
      await create(occurredAt: DateTime(2026, 10, 4), place: '한림읍');

      expect(await places(query: ' 애월 '), ['애월읍 2', '애월 카페 1']);
      expect(await places(query: '읍'), ['애월읍 2', '한림읍 1']);
    });

    test('ASCII 대소문자 무시 · % 는 글자 그대로', () async {
      await create(occurredAt: DateTime(2026, 10, 1), place: 'Aewol Cafe');
      await create(occurredAt: DateTime(2026, 10, 2), place: '100% 카페');
      await create(occurredAt: DateTime(2026, 10, 3), place: '1000 카페');

      expect(await places(query: 'aewol'), ['Aewol Cafe 1']);
      expect(await places(query: '0%'), ['100% 카페 1']);
    });

    test('빈 입력이면 상위 N 개, 휴지통 제외 · 0 개 숨김', () async {
      final trashed = await create(
        occurredAt: DateTime(2026, 10, 9),
        place: '서귀포',
      );
      await create(occurredAt: DateTime(2026, 10, 1), place: '애월읍');
      await create(occurredAt: DateTime(2026, 10, 2), place: '애월읍');
      await create(occurredAt: DateTime(2026, 10, 3), place: '한림읍');
      await create(occurredAt: DateTime(2026, 10, 4), place: '성산읍');
      okValue(await h.repository.trashEntry(trashed.id));

      expect(await places(limit: 2), ['애월읍 2', '성산읍 1']);
      expect(await places(), ['애월읍 2', '성산읍 1', '한림읍 1']);
    });
  });
}
