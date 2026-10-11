import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/named_count.dart';
import 'package:walk/domain/diary/entity/story.dart';

import '../../support/diary_fixtures.dart';

/// 스펙 §9.3.2 해시태그 반영. 각 단계는 테스트 처음에 연 같은 구독의 다음
/// 이벤트로 확인한다(스트림이 추가 · 휴지통 · 복원 · 수정 · 영구 삭제를 반영하는지).
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

  Future<DiaryEntry> create({
    String storyId = Story.dailyId,
    required DateTime occurredAt,
    List<String> tags = const [],
  }) async => okValue(
    await h.repository.createEntry(
      entryDraft(storyId: storyId, occurredAt: occurredAt, tags: tags),
    ),
  );

  /// 태그 목록 · 모아보기(제주) · 추천('제') 을 지금 구독한다.
  Future<
    ({
      List<List<NamedCount>> list,
      List<List<DiaryEntry>> gathered,
      List<List<NamedCount>> suggested,
    })
  >
  watchAll() async => (
    list: await recordEvents(h.repository.watchTagCounts()),
    gathered: await recordEvents(
      h.repository.watchEntries(const EntryFilter.tag('#제주')),
    ),
    suggested: await recordEvents(h.repository.watchTagCounts(query: '제')),
  );

  Future<String> tagIdOf(String name) async => (await (h.db.select(
    h.db.tags,
  )..where((t) => t.name.equals(name))).getSingle()).id;

  test('#제주 기록 1개 추가 → 목록 제주 1 · 모아보기에 그 기록', () async {
    final w = await watchAll();
    expect(w.list.last, isEmpty);
    expect(w.gathered.last, isEmpty);

    final a = await create(occurredAt: DateTime(2026, 10, 1), tags: ['#제주']);
    await pumpEventQueue();

    expect(namedCounts(w.list.last), ['제주 1']);
    expect(w.gathered.last.map((e) => e.id), [a.id]);
    expect(namedCounts(w.suggested.last), ['제주 1']);
  });

  test('다른 스토리에 #제주 추가 → 제주 2 · 모아보기에 두 스토리 기록이 occurredAt 순', () async {
    final a = await create(occurredAt: DateTime(2026, 10, 3), tags: ['#제주']);
    final w = await watchAll();
    expect(namedCounts(w.list.last), ['제주 1']);

    final b = await create(
      storyId: trip.id,
      occurredAt: DateTime(2026, 10, 2),
      tags: ['#제주'],
    );
    await pumpEventQueue();

    expect(namedCounts(w.list.last), ['제주 2']);
    expect(w.gathered.last.map((e) => (e.id, e.storyId)), [
      (a.id, Story.dailyId),
      (b.id, trip.id),
    ]);
  });

  test('하나를 휴지통으로 → 제주 1 · 모아보기에서 사라짐 · 추천 순서 재계산', () async {
    final early = await create(
      occurredAt: DateTime(2026, 10, 1),
      tags: ['#제주'],
    );
    final recent = await create(
      storyId: trip.id,
      occurredAt: DateTime(2026, 10, 3),
      tags: ['#제주'],
    );
    await create(occurredAt: DateTime(2026, 10, 2), tags: ['#제천']);
    final w = await watchAll();
    expect(namedCounts(w.suggested.last), ['제주 2', '제천 1']);

    okValue(await h.repository.trashEntry(recent.id));
    await pumpEventQueue();

    expect(namedCounts(w.list.last), ['제천 1', '제주 1']);
    expect(w.gathered.last.map((e) => e.id), [early.id]);
    // 같은 1 이면 최근에 쓴 제천(10/2)이 남은 제주(10/1)보다 앞.
    expect(namedCounts(w.suggested.last), ['제천 1', '제주 1']);
    expect(
      w.suggested.last.firstWhere((c) => c.name == '제주').lastUsedAt,
      DateTime(2026, 10, 1),
    );
  });

  test('마지막 하나도 휴지통으로 → 목록 · 추천에서 사라짐 · tags 행은 남음', () async {
    final a = await create(occurredAt: DateTime(2026, 10, 1), tags: ['#제주']);
    final b = await create(occurredAt: DateTime(2026, 10, 2), tags: ['#제주']);
    final w = await watchAll();
    okValue(await h.repository.trashEntry(a.id));
    await pumpEventQueue();
    expect(namedCounts(w.list.last), ['제주 1']);

    okValue(await h.repository.trashEntry(b.id));
    await pumpEventQueue();

    expect(w.list.last, isEmpty);
    expect(w.suggested.last, isEmpty);
    expect(w.gathered.last, isEmpty);
    expect(await tagIdOf('제주'), isNotEmpty);
  });

  test('하나 복원 → 제주 1 · 같은 tags.id(새 행 없음)', () async {
    final a = await create(occurredAt: DateTime(2026, 10, 1), tags: ['#제주']);
    final idBefore = await tagIdOf('제주');
    okValue(await h.repository.trashEntry(a.id));
    final w = await watchAll();
    expect(w.list.last, isEmpty);

    okValue(await h.repository.restoreEntry(a.id));
    await pumpEventQueue();

    expect(namedCounts(w.list.last), ['제주 1']);
    expect(w.gathered.last.map((e) => e.id), [a.id]);
    expect(await tagIdOf('제주'), idBefore);
    expect(await h.db.select(h.db.tags).get(), hasLength(1));
  });

  test('수정으로 #제주 → #부산 → 제주 -1 · 부산 +1 · 옛 entry_tags 없음', () async {
    final a = await create(occurredAt: DateTime(2026, 10, 1), tags: ['#제주']);
    await create(occurredAt: DateTime(2026, 10, 2), tags: ['#제주']);
    final w = await watchAll();
    expect(namedCounts(w.list.last), ['제주 2']);

    okValue(
      await h.repository.updateEntry(
        a.id,
        entryDraft(occurredAt: DateTime(2026, 10, 1), tags: ['#부산']),
      ),
    );
    await pumpEventQueue();

    expect(namedCounts(w.list.last), ['제주 1', '부산 1']);
    expect(w.gathered.last.map((e) => e.id), isNot(contains(a.id)));
    final links = await (h.db.select(
      h.db.entryTags,
    )..where((t) => t.entryId.equals(a.id))).get();
    expect([for (final l in links) l.tagId], [await tagIdOf('부산')]);
  });

  test('영구 삭제 → entry_tags 삭제 · 다른 기록이 쓰는 태그 유지 · 안 쓰는 tags 행 정리', () async {
    final gone = await create(
      occurredAt: DateTime(2026, 10, 1),
      tags: ['#제주', '#부산'],
    );
    final kept = await create(occurredAt: DateTime(2026, 10, 2), tags: ['#제주']);
    final w = await watchAll();
    expect(namedCounts(w.list.last), ['제주 2', '부산 1']);
    okValue(await h.repository.trashEntry(gone.id));
    await pumpEventQueue();
    expect(namedCounts(w.list.last), ['제주 1']);

    okValue(await h.repository.purgeEntries([gone.id]));
    await pumpEventQueue();

    expect(namedCounts(w.list.last), ['제주 1']);
    expect(w.gathered.last.map((e) => e.id), [kept.id]);
    final links = await h.db.select(h.db.entryTags).get();
    expect([for (final l in links) l.entryId], [kept.id]);
    expect(
      [for (final t in await h.db.select(h.db.tags).get()) t.name],
      ['제주'],
    );
  });

  test('휴지통 기록만 가진 태그로 검색 → 결과 0 · 추천 없음', () async {
    final a = await create(occurredAt: DateTime(2026, 10, 1), tags: ['#제주']);
    await create(occurredAt: DateTime(2026, 10, 2), tags: ['#부산']);
    okValue(await h.repository.trashEntry(a.id));

    expect(
      await h.repository.watchEntries(const EntryFilter.tag('제주')).first,
      isEmpty,
    );
    expect(await h.repository.watchTagCounts(query: '제주').first, isEmpty);
    expect(namedCounts(await h.repository.watchTagCounts().first), ['부산 1']);
  });
}
