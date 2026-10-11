import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_usage.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';

import '../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;

  setUp(() => h = DiaryHarness());
  tearDown(() => h.close());

  Future<String> create(List<EntryMedia> media) async =>
      okValue(await h.repository.createEntry(entryDraft(media: media))).id;

  test('기록이 없으면 모두 0', () async {
    expect(
      await h.repository.usage(),
      const DiaryUsage(photos: 0, videos: 0, bytes: 0, trashBytes: 0),
    );
  });

  test('사진 · 영상 개수와 바이트 합', () async {
    // 사진 1000 바이트, 영상 50000 바이트(fixtures).
    await create([photoMedia('p1'), photoMedia('p2'), videoMedia('v1')]);
    await create([photoMedia('p3')]);

    expect(
      await h.repository.usage(),
      const DiaryUsage(photos: 3, videos: 1, bytes: 53000, trashBytes: 0),
    );
  });

  test('휴지통 기록의 바이트는 trashBytes 로 따로(합계에도 포함)', () async {
    await create([photoMedia('p1')]);
    final trashed = await create([photoMedia('p2'), videoMedia('v1')]);
    okValue(await h.repository.trashEntry(trashed));

    expect(
      await h.repository.usage(),
      const DiaryUsage(photos: 2, videos: 1, bytes: 52000, trashBytes: 51000),
    );
  });

  test('영구 삭제하면 그 몫이 빠진다', () async {
    await create([photoMedia('p1')]);
    final trashed = await create([videoMedia('v1')]);
    okValue(await h.repository.trashEntry(trashed));
    okValue(await h.repository.purgeEntries([trashed]));

    expect(
      await h.repository.usage(),
      const DiaryUsage(photos: 1, videos: 0, bytes: 1000, trashBytes: 0),
    );
  });
}
