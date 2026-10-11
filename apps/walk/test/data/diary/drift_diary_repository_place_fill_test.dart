import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';

import '../../support/diary_fixtures.dart';

/// 스펙 §9.3 장소 지연 채우기: 좌표만 있는 기록 목록과 이름 채우기.
void main() {
  late DiaryHarness h;

  setUp(() => h = DiaryHarness());
  tearDown(() => h.close());

  const coordsOnly = EntryLocation(lat: 33.46, lng: 126.33);

  Future<String> create({
    String storyId = Story.dailyId,
    EntryLocation? location,
  }) async => okValue(
    await h.repository.createEntry(
      entryDraft(
        storyId: storyId,
        occurredAt: DateTime(2026, 10, 1),
        location: location,
      ),
    ),
  ).id;

  test('좌표만 있고 장소가 없는 기록만 돌려준다', () async {
    final offline = await create(location: coordsOnly);
    await create(); // 위치 없음
    await create(
      location: const EntryLocation(placeName: '애월읍', lat: 1, lng: 2),
    ); // 이미 이름 있음
    await create(location: const EntryLocation(placeName: '직접 입력')); // 좌표 없음

    final missing = await h.repository.entriesMissingPlaceName();

    expect(missing.map((e) => e.id), [offline]);
    expect(missing.single.location, coordsOnly);
  });

  test('어느 스토리의 기록이든 대상이다', () async {
    final trip = okValue(
      await h.repository.createStory(
        title: '여행',
        startedAt: DateTime(2026, 9, 1),
      ),
    );
    final id = await create(storyId: trip.id, location: coordsOnly);

    expect((await h.repository.entriesMissingPlaceName()).map((e) => e.id), [
      id,
    ]);
  });

  test('휴지통 기록은 제외하고, 복원하면 다시 대상이다', () async {
    final id = await create(location: coordsOnly);
    okValue(await h.repository.trashEntry(id));
    expect(await h.repository.entriesMissingPlaceName(), isEmpty);

    okValue(await h.repository.restoreEntry(id));

    expect((await h.repository.entriesMissingPlaceName()).map((e) => e.id), [
      id,
    ]);
  });

  test('채우면 이름이 붙고 좌표 · updatedAt 은 그대로, 더는 대상이 아니다', () async {
    final id = await create(location: coordsOnly);
    final before = okValue(await h.repository.entry(id));
    h.clock.advance(const Duration(hours: 1));

    okValue(await h.repository.fillPlaceName(id, ' 애월읍 '));

    final after = okValue(await h.repository.entry(id));
    expect(
      after.location,
      const EntryLocation(placeName: '애월읍', lat: 33.46, lng: 126.33),
    );
    expect(after.updatedAt, before.updatedAt);
    expect(await h.repository.entriesMissingPlaceName(), isEmpty);
  });

  test('같은 이름의 기존 장소와 합쳐져 places 행은 하나다', () async {
    await create(
      location: const EntryLocation(placeName: '애월읍', lat: 33.4, lng: 126.3),
    );
    final offline = await create(location: coordsOnly);

    okValue(await h.repository.fillPlaceName(offline, '애월읍'));

    expect((await h.db.select(h.db.places).get()).length, 1);
  });

  test('없는 기록은 notFound', () async {
    final result = await h.repository.fillPlaceName('nope', '애월읍');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, const Failure.notFound());
  });

  test('빈 이름은 아무것도 하지 않는다', () async {
    final id = await create(location: coordsOnly);

    okValue(await h.repository.fillPlaceName(id, '  '));

    expect((await h.repository.entriesMissingPlaceName()).length, 1);
    expect(await h.db.select(h.db.places).get(), isEmpty);
  });

  test('이미 장소가 있는 기록은 덮어쓰지 않는다', () async {
    final id = await create(
      location: const EntryLocation(placeName: '직접', lat: 1, lng: 2),
    );

    okValue(await h.repository.fillPlaceName(id, '자동'));

    expect(okValue(await h.repository.entry(id)).location?.placeName, '직접');
    expect((await h.db.select(h.db.places).get()).length, 1);
  });
}
