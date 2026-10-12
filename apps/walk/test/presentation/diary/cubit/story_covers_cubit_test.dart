import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/usecase/story_cover.dart';
import 'package:walk/presentation/diary/cubit/story_covers_cubit.dart';

import '../../../support/diary_fixtures.dart';

void main() {
  late DiaryHarness h;
  late StoryCoversCubit cubit;

  setUp(() async {
    h = DiaryHarness();
    cubit = StoryCoversCubit(h.repository)..start();
    await pumpEventQueue();
  });

  tearDown(() async {
    await cubit.close();
    await h.close();
  });

  String? coverId(String storyId) => switch (cubit.state[storyId]) {
    CoverMedia(:final media) => media.id,
    _ => null,
  };

  test('사진이 없으면 이니셜, 기록에 사진이 생기면 그 사진', () async {
    expect(cubit.state[Story.dailyId], isA<CoverInitial>());

    await h.repository.createEntry(entryDraft(media: [photoMedia('p1')]));
    await pumpEventQueue();

    expect(coverId(Story.dailyId), 'p1');
  });

  test('고른 표지를 따르고, 그 기록이 휴지통에 가면 자동 표지로', () async {
    final trip = okValue(
      await h.repository.createStory(title: '제주', startedAt: diaryT0),
    );
    final chosen = okValue(
      await h.repository.createEntry(
        entryDraft(
          storyId: trip.id,
          occurredAt: diaryT0.subtract(const Duration(hours: 1)),
          media: [photoMedia('old')],
        ),
      ),
    );
    await h.repository.createEntry(
      entryDraft(storyId: trip.id, media: [photoMedia('new')]),
    );
    await h.repository.updateStory(trip.copyWith(coverMediaId: 'old'));
    await pumpEventQueue();
    expect(coverId(trip.id), 'old');

    await h.repository.trashEntry(chosen.id);
    await pumpEventQueue();

    expect(coverId(trip.id), 'new');
  });

  test('스토리마다 자기 기록에서만 고른다', () async {
    final trip = okValue(
      await h.repository.createStory(title: '제주', startedAt: diaryT0),
    );
    await h.repository.createEntry(entryDraft(media: [photoMedia('daily')]));
    await pumpEventQueue();

    expect(coverId(Story.dailyId), 'daily');
    expect(cubit.state[trip.id], isA<CoverInitial>());
  });
}
