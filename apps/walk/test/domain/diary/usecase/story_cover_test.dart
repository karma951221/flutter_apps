import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/usecase/story_cover.dart';

import '../../../support/diary_fixtures.dart';

void main() {
  final story = Story(
    id: 'jeju',
    title: '제주',
    status: StoryStatus.open,
    startedAt: DateTime(2026, 10, 1),
    createdAt: DateTime(2026, 10, 1),
  );

  DiaryEntry entry(
    String id, {
    required DateTime occurredAt,
    List<EntryMedia> media = const [],
    DateTime? deletedAt,
  }) => DiaryEntry(
    id: id,
    storyId: story.id,
    body: '',
    occurredAt: occurredAt,
    createdAt: occurredAt,
    updatedAt: occurredAt,
    deletedAt: deletedAt,
    media: media,
    tags: const [],
  );

  final older = entry(
    'older',
    occurredAt: DateTime(2026, 10, 2),
    media: [photoMedia('p-old1'), photoMedia('p-old2')],
  );
  final newer = entry(
    'newer',
    occurredAt: DateTime(2026, 10, 5),
    media: [videoMedia('v-new'), photoMedia('p-new')],
  );
  final textOnly = entry('text', occurredAt: DateTime(2026, 10, 9));

  test('지정한 표지가 살아 있는 기록의 미디어면 그것', () {
    final cover = StoryCoverRule.pick(story.copyWith(coverMediaId: 'p-old2'), [
      textOnly,
      newer,
      older,
    ]);

    expect(cover, StoryCover.media(photoMedia('p-old2')));
  });

  test('지정이 없으면 occurredAt 이 가장 최근인 기록의 첫 사진', () {
    final cover = StoryCoverRule.pick(story, [older, textOnly, newer]);

    expect(cover, StoryCover.media(photoMedia('p-new')));
  });

  test('지정한 표지의 기록이 휴지통이면 자동 표지(최신 사진)', () {
    // 호출자가 휴지통 기록을 빼고 넘긴 경우.
    final cover = StoryCoverRule.pick(story.copyWith(coverMediaId: 'p-old2'), [
      newer,
    ]);

    expect(cover, StoryCover.media(photoMedia('p-new')));
  });

  test('휴지통 기록이 섞여 넘어와도 그 미디어는 쓰지 않는다', () {
    final trashedOlder = entry(
      'older',
      occurredAt: DateTime(2026, 10, 2),
      media: [photoMedia('p-old1')],
      deletedAt: DateTime(2026, 10, 10),
    );
    final videoOnly = entry(
      'video',
      occurredAt: DateTime(2026, 10, 1),
      media: [videoMedia('v-only')],
    );

    final cover = StoryCoverRule.pick(story.copyWith(coverMediaId: 'p-old1'), [
      trashedOlder,
      videoOnly,
    ]);

    expect(cover, StoryCover.media(videoMedia('v-only')));
  });

  test('사진 없이 영상만 있으면 가장 최근 기록의 첫 영상(썸네일)', () {
    final a = entry(
      'a',
      occurredAt: DateTime(2026, 10, 2),
      media: [videoMedia('v-a')],
    );
    final b = entry(
      'b',
      occurredAt: DateTime(2026, 10, 3),
      media: [videoMedia('v-b1'), videoMedia('v-b2')],
    );

    expect(
      StoryCoverRule.pick(story, [a, b]),
      StoryCover.media(videoMedia('v-b1')),
    );
  });

  test('더 최근 기록에 영상만 있어도 사진이 있으면 사진이 먼저', () {
    final photo = entry(
      'photo',
      occurredAt: DateTime(2026, 10, 2),
      media: [photoMedia('p')],
    );
    final video = entry(
      'video',
      occurredAt: DateTime(2026, 10, 8),
      media: [videoMedia('v')],
    );

    expect(
      StoryCoverRule.pick(story, [video, photo]),
      StoryCover.media(photoMedia('p')),
    );
  });

  test('미디어가 없으면 제목 이니셜', () {
    expect(
      StoryCoverRule.pick(story, [textOnly]),
      const StoryCover.initial('제주'),
    );
    expect(StoryCoverRule.pick(story, []), const StoryCover.initial('제주'));
  });

  test('유일한 사진의 기록이 휴지통이면 이니셜', () {
    // 호출자가 살아 있는 기록만 넘긴다: 사진 기록은 빠지고 글 기록만 남는다.
    expect(
      StoryCoverRule.pick(story.copyWith(coverMediaId: 'p-old1'), [textOnly]),
      const StoryCover.initial('제주'),
    );
    // 휴지통 기록이 섞여 넘어와도 같다.
    final trashed = entry(
      'older',
      occurredAt: DateTime(2026, 10, 2),
      media: [photoMedia('p-old1')],
      deletedAt: DateTime(2026, 10, 10),
    );
    expect(
      StoryCoverRule.pick(story.copyWith(coverMediaId: 'p-old1'), [
        trashed,
        textOnly,
      ]),
      const StoryCover.initial('제주'),
    );
  });
}
