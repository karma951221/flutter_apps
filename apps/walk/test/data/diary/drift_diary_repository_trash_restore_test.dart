import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/usecase/story_cover.dart';
import 'package:walk/domain/diary/usecase/story_order.dart';

import '../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;
  late Story jeju;

  setUp(() async {
    h = DiaryHarness();
    jeju = okValue(
      await h.repository.createStory(
        title: '제주',
        startedAt: DateTime(2026, 10, 1),
      ),
    );
  });
  tearDown(() => h.close());

  Future<Story> storyOf(String id) async =>
      (await h.repository.watchStories().first).singleWhere((s) => s.id == id);

  Future<List<String>> idsIn(EntryFilter filter) async => [
    for (final e in await h.repository.watchEntries(filter).first) e.id,
  ];

  /// 사진 2 + 영상 1, 태그 · 장소 · 좌표가 있는 제주 기록.
  Future<DiaryEntry> richEntry({DateTime? occurredAt}) async => okValue(
    await h.repository.createEntry(
      entryDraft(
        storyId: jeju.id,
        body: '협재 바다',
        occurredAt: occurredAt ?? DateTime(2026, 10, 3, 14),
        location: const EntryLocation(
          placeName: '한림읍',
          lat: 33.394,
          lng: 126.239,
        ),
        media: [photoMedia('p1'), videoMedia('v1'), photoMedia('p2')],
        tags: ['jeju', 'sea'],
      ),
    ),
  );

  test('사진 2 + 영상 1 기록 삭제: media 행 3개 · 경로 그대로', () async {
    final entry = await richEntry();

    okValue(await h.repository.trashEntry(entry.id));

    final rows = await h.db.select(h.db.media).get();
    expect(rows, hasLength(3));
    expect(okValue(await h.repository.entry(entry.id)).media, entry.media);
    expect(await h.repository.allMediaPaths(), {
      'media/p1.jpg',
      'media/v1.mp4',
      'media/v1.thumb.jpg',
      'media/p2.jpg',
    });
  });

  test(
    '복원: id · 본문 · 시각 · 스토리 · 장소 · 좌표 · 미디어(순서 · 종류 · 크기 · 길이 · 경로)가 같다',
    () async {
      final entry = await richEntry();
      h.clock.advance(const Duration(hours: 3));
      okValue(await h.repository.trashEntry(entry.id));
      h.clock.advance(const Duration(days: 2));

      final restored = okValue(await h.repository.restoreEntry(entry.id));

      expect(restored.deletedAt, isNull);
      expect(restored.updatedAt, entry.updatedAt);
      // deletedAt 을 뺀 모든 값이 삭제 전과 같다.
      expect(restored, entry);
      expect(restored.id, entry.id);
      expect(restored.body, '협재 바다');
      expect(restored.occurredAt, entry.occurredAt);
      expect(restored.createdAt, entry.createdAt);
      expect(restored.storyId, jeju.id);
      expect(restored.location, entry.location);
      expect(restored.tags, ['jeju', 'sea']);
      expect([for (final m in restored.media) m.id], ['p1', 'v1', 'p2']);
      expect(
        [for (final m in restored.media) m.kind],
        [for (final m in entry.media) m.kind],
      );
      expect(
        [for (final m in restored.media) (m.width, m.height)],
        [for (final m in entry.media) (m.width, m.height)],
      );
      expect(
        [for (final m in restored.media) m.durationMs],
        [null, 12000, null],
      );
      expect(
        [for (final m in restored.media) (m.path, m.thumbPath)],
        [for (final m in entry.media) (m.path, m.thumbPath)],
      );
      expect(okValue(await h.repository.entry(entry.id)), restored);
    },
  );

  test('복원 후: 원래 스토리의 occurredAt 자리 · 전체 · 검색 · 태그 · 장소에 다시', () async {
    final before = okValue(
      await h.repository.createEntry(
        entryDraft(storyId: jeju.id, occurredAt: DateTime(2026, 10, 2)),
      ),
    );
    final entry = await richEntry(occurredAt: DateTime(2026, 10, 3));
    final after = okValue(
      await h.repository.createEntry(
        entryDraft(storyId: jeju.id, occurredAt: DateTime(2026, 10, 4)),
      ),
    );
    okValue(await h.repository.trashEntry(entry.id));
    expect(await idsIn(EntryFilter.story(jeju.id)), [after.id, before.id]);

    okValue(await h.repository.restoreEntry(entry.id));

    expect(await idsIn(EntryFilter.story(jeju.id)), [
      after.id,
      entry.id,
      before.id,
    ]);
    expect(await idsIn(const EntryFilter.all()), contains(entry.id));
    expect(await idsIn(const EntryFilter.body('협재')), [entry.id]);
    expect(await idsIn(const EntryFilter.tag('sea')), [entry.id]);
    expect(await idsIn(const EntryFilter.place('한림읍')), [entry.id]);
    expect(await h.repository.watchTrash().first, isEmpty);
  });

  test('표지 사진의 기록 삭제 → 자동 표지, 복원 → 지정 표지', () async {
    final covered = await richEntry(occurredAt: DateTime(2026, 10, 2));
    final latest = okValue(
      await h.repository.createEntry(
        entryDraft(
          storyId: jeju.id,
          occurredAt: DateTime(2026, 10, 5),
          media: [photoMedia('latest')],
        ),
      ),
    );
    okValue(await h.repository.updateStory(jeju.copyWith(coverMediaId: 'p2')));

    Future<StoryCover> cover() async => StoryCoverRule.pick(
      await storyOf(jeju.id),
      await h.repository.watchEntries(EntryFilter.story(jeju.id)).first,
    );

    expect(await cover(), StoryCover.media(covered.media[2]));
    okValue(await h.repository.trashEntry(covered.id));
    expect(await cover(), StoryCover.media(latest.media.single));
    okValue(await h.repository.restoreEntry(covered.id));
    expect(await cover(), StoryCover.media(covered.media[2]));
  });

  test('삭제된 동안 원래 스토리가 닫히면 닫힌 스토리로 복원, 보관함에서 보인다', () async {
    final entry = await richEntry();
    okValue(await h.repository.trashEntry(entry.id));
    okValue(
      await h.repository.updateStory(
        okValue(jeju.close(DateTime(2026, 10, 6))),
      ),
    );

    final restored = okValue(await h.repository.restoreEntry(entry.id));

    expect(restored.storyId, jeju.id);
    final order = StoryOrder.split(await h.repository.watchStories().first);
    expect(order.archived.map((s) => s.id), [jeju.id]);
    expect(await idsIn(EntryFilter.story(jeju.id)), [entry.id]);
  });

  test('삭제된 동안 원래 스토리가 삭제되면 "일상"으로 복원', () async {
    final entry = await richEntry();
    okValue(await h.repository.trashEntry(entry.id));
    okValue(await h.repository.deleteStory(jeju.id));

    final restored = okValue(await h.repository.restoreEntry(entry.id));

    expect(restored.storyId, Story.dailyId);
    expect(restored.media, entry.media);
    expect(restored.updatedAt, entry.updatedAt);
    expect(await idsIn(EntryFilter.story(Story.dailyId)), [entry.id]);
  });

  test('영구 삭제(자동 정리 포함) 뒤 복원은 notFound', () async {
    final manual = await richEntry();
    final expired = okValue(
      await h.repository.createEntry(entryDraft(storyId: jeju.id)),
    );
    okValue(await h.repository.trashEntry(manual.id));
    okValue(await h.repository.trashEntry(expired.id));
    okValue(await h.repository.purgeEntries([manual.id]));
    okValue(await h.repository.purgeTrashedBefore(h.clock.now()));

    expect(
      errFailure(await h.repository.restoreEntry(manual.id)),
      isA<NotFoundFailure>(),
    );
    expect(
      errFailure(await h.repository.restoreEntry(expired.id)),
      isA<NotFoundFailure>(),
    );
  });

  test('삭제 · 복원 모두 updatedAt 을 바꾸지 않는다', () async {
    final entry = await richEntry();
    h.clock.advance(const Duration(hours: 1));
    okValue(await h.repository.trashEntry(entry.id));
    expect(
      okValue(await h.repository.entry(entry.id)).updatedAt,
      entry.updatedAt,
    );
    h.clock.advance(const Duration(hours: 1));
    expect(
      okValue(await h.repository.restoreEntry(entry.id)).updatedAt,
      entry.updatedAt,
    );
  });

  test('휴지통에 없는 기록의 복원은 그대로 돌려준다', () async {
    final entry = await richEntry();
    expect(okValue(await h.repository.restoreEntry(entry.id)), entry);
  });
}
