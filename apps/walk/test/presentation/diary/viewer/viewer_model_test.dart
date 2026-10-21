import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/presentation/diary/viewer/viewer_model.dart';

import '../../../support/diary_fixtures.dart';

DiaryEntry entry(
  String id,
  DateTime at, {
  List<EntryMedia> media = const [],
  bool trashed = false,
}) => DiaryEntry(
  id: id,
  storyId: 's',
  body: id,
  occurredAt: at,
  createdAt: at,
  updatedAt: at,
  deletedAt: trashed ? at : null,
  media: media,
  tags: const [],
);

Story story({bool open = true, DateTime? start}) => Story(
  id: 's',
  title: '제주',
  status: open ? StoryStatus.open : StoryStatus.closed,
  startedAt: start ?? DateTime(2026, 10, 6, 9),
  endedAt: open ? null : DateTime(2026, 10, 8),
  createdAt: DateTime(2026, 10, 6),
);

ViewerGroup trip({bool open = true}) => buildViewerGroup(
  id: 's',
  title: '제주',
  story: story(open: open),
  entries: [
    entry('c', DateTime(2026, 10, 7, 15), media: [videoMedia('v')]),
    entry(
      'a',
      DateTime(2026, 10, 6, 10),
      media: [photoMedia('p1'), photoMedia('p2')],
    ),
    entry('b', DateTime(2026, 10, 7, 9)),
  ],
);

ViewerGroup empty(String id) =>
    buildViewerGroup(id: id, title: id, entries: const []);

void main() {
  test('날짜별로 묶고 기록 안 미디어마다 조각, 글 기록은 조각 하나', () {
    final g = trip();
    expect(g.days.length, 2);
    expect(g.days.map((d) => d.slides.length), [2, 2]);
    expect(g.days[1].slides[0].media, isNull);
    expect(g.days[1].slides[0].entry.id, 'b');
    expect(g.days[1].slides[1].media?.id, 'v');
    expect(g.days[0].date, DateTime(2026, 10, 6));
  });

  test('휴지통 기록은 빼고 빈 그룹은 날이 없다', () {
    final g = buildViewerGroup(
      id: 'x',
      title: 'x',
      entries: [entry('t', DateTime(2026, 10, 6), trashed: true)],
    );
    expect(g.days, isEmpty);
    expect(startPos([g], 0), isNull);
  });

  test('진행 중은 마지막 날, 닫힘 · fromStart 는 첫날, entryId 는 그 기록', () {
    expect(startPos([trip()], 0), const ViewerPos(0, 1, 0));
    expect(startPos([trip(open: false)], 0), const ViewerPos(0, 0, 0));
    expect(startPos([trip()], 0, fromStart: true), const ViewerPos(0, 0, 0));
    expect(startPos([trip()], 0, entryId: 'c'), const ViewerPos(0, 1, 1));
    expect(startPos([trip()], 0, entryId: 'a'), const ViewerPos(0, 0, 0));
    // 모아보기(story == null)는 마지막 날.
    final filter = buildViewerGroup(
      id: 'f',
      title: '#제주',
      entries: [
        entry('a', DateTime(2026, 10, 6)),
        entry('b', DateTime(2026, 10, 7)),
      ],
    );
    expect(startPos([filter], 0), const ViewerPos(0, 1, 0));
  });

  test('nextPos 는 날을 넘고 그룹을 넘고 끝에서 null', () {
    final gs = [trip(open: false), trip(open: false)];
    expect(nextPos(gs, const ViewerPos(0, 0, 0)), const ViewerPos(0, 0, 1));
    expect(nextPos(gs, const ViewerPos(0, 0, 1)), const ViewerPos(0, 1, 0));
    expect(nextPos(gs, const ViewerPos(0, 1, 1)), const ViewerPos(1, 0, 0));
    expect(nextPos(gs, const ViewerPos(1, 1, 1)), isNull);
  });

  test('prevPos 는 전날 마지막 조각, 맨 처음에선 그대로', () {
    final gs = [trip(open: false), trip(open: false)];
    expect(prevPos(gs, const ViewerPos(0, 1, 0)), const ViewerPos(0, 0, 1));
    expect(prevPos(gs, const ViewerPos(1, 0, 0)), const ViewerPos(0, 1, 1));
    expect(prevPos(gs, const ViewerPos(0, 1, 1)), const ViewerPos(0, 1, 0));
    expect(prevPos(gs, const ViewerPos(0, 0, 0)), const ViewerPos(0, 0, 0));
  });

  test('빈 그룹은 건너뛴다', () {
    final gs = [trip(open: false), empty('e'), trip(open: false)];
    expect(nextPos(gs, const ViewerPos(0, 1, 1)), const ViewerPos(2, 0, 0));
    expect(prevPos(gs, const ViewerPos(2, 0, 0)), const ViewerPos(0, 1, 1));
    expect(
      groupStep(gs, const ViewerPos(0, 0, 0), 1),
      const ViewerPos(2, 0, 0),
    );
    expect(
      groupStep(gs, const ViewerPos(2, 0, 0), -1),
      const ViewerPos(0, 0, 0),
    );
    expect(groupStep(gs, const ViewerPos(2, 0, 0), 1), isNull);
    expect(
      groupStep([trip(), empty('e')], const ViewerPos(0, 0, 0), 1),
      isNull,
    );
  });

  test('dayNumber: 시작 10/6 이면 10/7 은 2, 일상 · 모아보기는 null', () {
    final g = trip();
    expect(dayNumber(g, g.days[0]), 1);
    expect(dayNumber(g, g.days[1]), 2);
    final daily = ViewerGroup(
      id: Story.dailyId,
      title: '일상',
      story: Story(
        id: Story.dailyId,
        title: '',
        status: StoryStatus.open,
        startedAt: DateTime(2026, 10, 6),
        createdAt: DateTime(2026, 10, 6),
      ),
      days: g.days,
    );
    expect(dayNumber(daily, daily.days[1]), isNull);
    final filter = buildViewerGroup(
      id: 'f',
      title: '#a',
      entries: [entry('a', DateTime(2026, 10, 7))],
    );
    expect(dayNumber(filter, filter.days[0]), isNull);
  });
}
