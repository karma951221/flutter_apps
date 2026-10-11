import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/named_count.dart';
import 'package:walk/domain/diary/entity/story.dart';

import '../../support/diary_fixtures.dart';

/// 스펙 §9.3.3 장소 반영. 오프라인 기록 이름 채우기 두 행은 `fillPlaceName`
/// 이 생기는 T8 에서 더한다. 각 단계는 같은 구독의 다음 이벤트로 확인한다.
void main() {
  late DiaryHarness h;
  late Story trip;

  setUp(() async {
    h = DiaryHarness();
    trip = okValue(
      await h.repository.createStory(
        title: '제주 여행',
        startedAt: DateTime(2026, 9, 1),
      ),
    );
  });
  tearDown(() => h.close());

  const aewol = EntryLocation(placeName: '애월읍', lat: 33.46, lng: 126.33);

  Future<DiaryEntry> create({
    String storyId = Story.dailyId,
    required DateTime occurredAt,
    EntryLocation? location,
  }) async => okValue(
    await h.repository.createEntry(
      entryDraft(storyId: storyId, occurredAt: occurredAt, location: location),
    ),
  );

  /// 장소 목록 · 모아보기(애월읍) · 추천('애월') 을 지금 구독한다.
  Future<
    ({
      List<List<NamedCount>> list,
      List<List<DiaryEntry>> gathered,
      List<List<NamedCount>> suggested,
    })
  >
  watchAll() async => (
    list: await recordEvents(h.repository.watchPlaceCounts()),
    gathered: await recordEvents(
      h.repository.watchEntries(const EntryFilter.place('애월읍')),
    ),
    suggested: await recordEvents(h.repository.watchPlaceCounts(query: '애월')),
  );

  Future<List<String>> placeRows() async => [
    for (final p in await h.db.select(h.db.places).get()) p.name,
  ];

  test('"애월읍" 기록 추가 → 같은 장소 하나 더 → places 행 1 · 애월읍 2 · 모아보기 2개', () async {
    final w = await watchAll();
    expect(w.list.last, isEmpty);

    final a = await create(occurredAt: DateTime(2026, 10, 1), location: aewol);
    await pumpEventQueue();
    expect(namedCounts(w.list.last), ['애월읍 1']);

    final b = await create(
      storyId: trip.id,
      occurredAt: DateTime(2026, 10, 2),
      location: const EntryLocation(placeName: ' 애월읍 ', lat: 33.47, lng: 126.3),
    );
    await pumpEventQueue();

    expect(await placeRows(), ['애월읍']);
    expect(namedCounts(w.list.last), ['애월읍 2']);
    expect(namedCounts(w.suggested.last), ['애월읍 2']);
    expect(w.gathered.last.map((e) => e.id), [b.id, a.id]);
  });

  test('하나 휴지통 → 복원 → 애월읍 1 → 2 · 같은 places.id · 좌표 그대로', () async {
    final a = await create(occurredAt: DateTime(2026, 10, 1), location: aewol);
    await create(occurredAt: DateTime(2026, 10, 2), location: aewol);
    final placeId = (await h.db.select(h.db.places).getSingle()).id;
    final w = await watchAll();
    expect(namedCounts(w.list.last), ['애월읍 2']);

    okValue(await h.repository.trashEntry(a.id));
    await pumpEventQueue();
    expect(namedCounts(w.list.last), ['애월읍 1']);
    expect(w.gathered.last.map((e) => e.id), isNot(contains(a.id)));

    final restored = okValue(await h.repository.restoreEntry(a.id));
    await pumpEventQueue();

    expect(namedCounts(w.list.last), ['애월읍 2']);
    expect(w.gathered.last.map((e) => e.id), contains(a.id));
    expect((await h.db.select(h.db.places).getSingle()).id, placeId);
    expect(restored.location, aewol);
  });

  test('모두 휴지통 → 목록 · 추천에서 숨김 · 행은 남음', () async {
    final a = await create(occurredAt: DateTime(2026, 10, 1), location: aewol);
    final b = await create(occurredAt: DateTime(2026, 10, 2), location: aewol);
    final w = await watchAll();

    okValue(await h.repository.trashEntry(a.id));
    okValue(await h.repository.trashEntry(b.id));
    await pumpEventQueue();

    expect(w.list.last, isEmpty);
    expect(w.suggested.last, isEmpty);
    expect(w.gathered.last, isEmpty);
    expect(await placeRows(), ['애월읍']);
  });

  test(
    '수정으로 장소 변경 · 제거 → 이전 -1 · 새 +1 · 위치 끄면 placeId · lat · lng 모두 null',
    () async {
      final a = await create(
        occurredAt: DateTime(2026, 10, 1),
        location: aewol,
      );
      final b = await create(
        occurredAt: DateTime(2026, 10, 2),
        location: aewol,
      );
      final w = await watchAll();
      expect(namedCounts(w.list.last), ['애월읍 2']);

      okValue(
        await h.repository.updateEntry(
          a.id,
          entryDraft(
            occurredAt: DateTime(2026, 10, 1),
            location: const EntryLocation(placeName: '한림읍'),
          ),
        ),
      );
      await pumpEventQueue();
      expect(namedCounts(w.list.last), ['애월읍 1', '한림읍 1']);

      okValue(
        await h.repository.updateEntry(
          b.id,
          entryDraft(occurredAt: DateTime(2026, 10, 2)),
        ),
      );
      await pumpEventQueue();

      expect(namedCounts(w.list.last), ['한림읍 1']);
      expect(w.suggested.last, isEmpty);
      expect(w.gathered.last, isEmpty);
      final row = await (h.db.select(
        h.db.entries,
      )..where((e) => e.id.equals(b.id))).getSingle();
      expect((row.placeId, row.lat, row.lng), (null, null, null));
    },
  );

  test('영구 삭제 → 쓰는 기록 없는 places 행 정리 · 다른 기록이 쓰는 장소 유지', () async {
    final gone = await create(
      occurredAt: DateTime(2026, 10, 1),
      location: const EntryLocation(placeName: '한림읍'),
    );
    final sharing = await create(
      occurredAt: DateTime(2026, 10, 2),
      location: aewol,
    );
    final kept = await create(
      occurredAt: DateTime(2026, 10, 3),
      location: aewol,
    );
    final w = await watchAll();
    okValue(await h.repository.trashEntry(gone.id));
    okValue(await h.repository.trashEntry(sharing.id));
    await pumpEventQueue();
    expect(namedCounts(w.list.last), ['애월읍 1']);

    okValue(await h.repository.purgeEntries([gone.id, sharing.id]));
    await pumpEventQueue();

    expect(namedCounts(w.list.last), ['애월읍 1']);
    expect(w.gathered.last.map((e) => e.id), [kept.id]);
    expect(await placeRows(), ['애월읍']);
  });
}
