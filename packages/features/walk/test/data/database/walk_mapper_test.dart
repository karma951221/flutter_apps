import 'package:feature_walk/src/data/database/walk_database.dart';
import 'package:feature_walk/src/data/database/walk_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  DogRow dogRow(String id, String name) =>
      DogRow(id: id, name: name, createdAt: t0, updatedAt: t0);

  WalkRow walkRow(String id, DateTime startedAt) => WalkRow(
    id: id,
    startedAt: startedAt,
    endedAt: t1,
    durationSeconds: 1800,
    distanceMeters: 100,
    routePreview: '[[37.5,127.0]]',
    createdAt: t0,
    updatedAt: t0,
  );

  WalkPhotoRow photoRow(String id, String walkId, int position) => WalkPhotoRow(
    id: id,
    walkId: walkId,
    path: '$id.jpg',
    position: position,
    createdAt: t0,
  );

  test('조인 행을 산책별로 묶고 중복을 제거한다', () {
    final w1 = walkRow('w1', t1);
    final w2 = walkRow('w2', t0);
    final b = dogRow('d1', '하늘');
    final a = dogRow('d2', '가을');
    final p0 = photoRow('p0', 'w1', 0);
    final p1 = photoRow('p1', 'w1', 1);

    final walks = walksFromJoinRows([
      (walk: w1, dog: b, photo: p0),
      (walk: w1, dog: b, photo: p1),
      (walk: w1, dog: a, photo: p0),
      (walk: w1, dog: a, photo: p1),
      (walk: w2, dog: null, photo: null),
    ]);

    expect(walks.map((w) => w.id), ['w1', 'w2']);
    expect(walks[0].dogs.map((d) => d.name), ['가을', '하늘']);
    expect(walks[0].photos.map((p) => p.id), ['p0', 'p1']);
    expect(walks[0].previewPoints.single.lat, 37.5);
    expect(walks[1].dogs, isEmpty);
    expect(walks[1].photos, isEmpty);
  });
}
