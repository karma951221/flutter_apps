import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/dog/entity/dog.dart';
import 'package:pawlog/domain/social/entity/walk_post_draft.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';

import '../../../support/fakes.dart';

Dog _named(String id, String name) =>
    Dog(id: id, name: name, createdAt: t0, updatedAt: t0);

/// 위도 0.0001도 ≈ 11.1 m 간격, [count] 개.
List<WalkTrackPoint> _track(int count) => [
  for (var i = 0; i < count; i++) trackPoint(37 + i * 0.0001),
];

void main() {
  test('산책의 id · 시각 · 시간 · 거리 · 반려견 이름 · 메모를 옮긴다', () {
    final source = walk(
      dogs: [_named('d1', '콩이'), _named('d2', '보리')],
    ).copyWith(memo: '공원 한 바퀴');

    final draft = WalkPostDraft.fromWalk(source, const []);

    expect(draft.localWalkId, 'w1');
    expect(draft.startedAt, t0);
    expect(draft.duration, const Duration(minutes: 30));
    expect(draft.distanceMeters, 1200);
    expect(draft.dogNames, ['콩이', '보리']);
    expect(draft.memo, '공원 한 바퀴');
    expect(draft.routePreview, isEmpty);
  });

  test('경로는 앞뒤 150 m 를 잘라 낸다', () {
    final track = _track(90);

    final draft = WalkPostDraft.fromWalk(walk(), track);

    expect(draft.routePreview, isNotEmpty);
    expect(draft.routePreview.first, isNot(track.first.point));
    expect(draft.routePreview.last, isNot(track.last.point));
    expect(draft.routePreview.length, lessThanOrEqualTo(64));
  });

  test('트랙이 없으면 목록용 미리보기 점을 잘라 쓴다', () {
    final preview = [for (final p in _track(90)) p.point];

    final draft = WalkPostDraft.fromWalk(
      walk().copyWith(previewPoints: preview),
      const [],
    );

    expect(draft.routePreview, isNotEmpty);
    expect(draft.routePreview.first, isNot(preview.first));
  });

  test('메모는 500자(코드 포인트)로 자르고, 비었으면 null', () {
    final long = '🐶' * 600;

    final cut = WalkPostDraft.fromWalk(walk().copyWith(memo: long), const []);
    final blank = WalkPostDraft.fromWalk(walk().copyWith(memo: '  '), const []);

    expect(cut.memo!.runes.length, 500);
    expect(cut.memo, '🐶' * 500);
    expect(blank.memo, isNull);
  });

  test('반려견 이름은 다듬어 30자로 자르고 10마리까지만, 빈 이름은 뺀다', () {
    final dogs = [
      _named('d0', '  ${'가' * 40}  '),
      _named('blank', '   '),
      for (var i = 1; i <= 12; i++) _named('d$i', '개$i'),
    ];

    final draft = WalkPostDraft.fromWalk(walk(dogs: dogs), const []);

    expect(draft.dogNames, hasLength(10));
    expect(draft.dogNames.first, '가' * 30);
    expect(draft.dogNames, isNot(contains('')));
    expect(draft.dogNames.last, '개9');
  });
}
