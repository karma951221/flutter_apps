import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

List<Walk> _walks(Result<List<Walk>> r) => (r as Ok<List<Walk>>).value;

void main() {
  late WalkDatabase db;
  late DriftDogRepository dogs;
  late DriftWalkRepository repository;

  Dog named(String id, String name) =>
      Dog(id: id, name: name, createdAt: t0, updatedAt: t0);

  Walk walkOf(
    String id, {
    required DateTime startedAt,
    List<Dog> withDogs = const [],
    List<WalkPhoto> photos = const [],
    String? memo,
  }) => Walk(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 30)),
    duration: const Duration(minutes: 30),
    distanceMeters: 1200.5,
    memo: memo,
    dogs: withDogs,
    photos: photos,
    previewPoints: const [GeoPoint(lat: 37.5, lng: 127.0)],
    createdAt: t0,
    updatedAt: t0,
  );

  Future<int> count(TableInfo<Table, dynamic> table) async =>
      (await db.select(table).get()).length;

  setUp(() async {
    db = WalkDatabase(NativeDatabase.memory());
    dogs = DriftDogRepository(db);
    repository = DriftWalkRepository(db);
    await dogs.upsert(named('d1', '하늘'));
    await dogs.upsert(named('d2', '가을'));
  });
  tearDown(() => db.close());

  test('트랜잭션으로 walk · dogs · points · photos 를 저장한다', () async {
    final walk = walkOf(
      'w1',
      startedAt: t0,
      withDogs: [named('d1', '하늘'), named('d2', '가을')],
      photos: const [
        WalkPhoto(id: 'p2', path: 'b.jpg', position: 1),
        WalkPhoto(id: 'p1', path: 'a.jpg', position: 0),
      ],
      memo: '좋았다',
    );

    final result = await repository.insert(walk, [
      trackPoint(37.1),
      trackPoint(37.2),
    ]);

    expect(result, isA<Ok<void>>());
    final loaded = ((await repository.findById('w1')) as Ok<Walk?>).value!;
    expect(loaded.memo, '좋았다');
    expect(loaded.duration, const Duration(minutes: 30));
    expect(loaded.distanceMeters, 1200.5);
    expect(loaded.dogs.map((d) => d.name), ['가을', '하늘']);
    expect(loaded.photos.map((p) => p.id), ['p1', 'p2']);
    expect(loaded.previewPoints.single.lat, 37.5);
    expect(await count(db.walkPoints), 2);
  });

  test('최신순으로 watch 된다', () async {
    await repository.insert(
      walkOf('old', startedAt: DateTime(2026, 10, 1), withDogs: [dog('d1')]),
      const [],
    );
    await repository.insert(
      walkOf('new', startedAt: DateTime(2026, 10, 3)),
      const [],
    );

    final result = _walks(await repository.watchAll().first);

    expect(result.map((w) => w.id), ['new', 'old']);
  });

  test('반려견 이름 변경이 피드에 반영된다', () async {
    await repository.insert(
      walkOf('w1', startedAt: t0, withDogs: [named('d1', '하늘')]),
      const [],
    );
    final names = <String>[];
    final sub = repository.watchAll().listen(
      (r) => names.add(_walks(r).single.dogs.single.name),
    );
    await pumpEventQueue();

    await dogs.upsert(named('d1', '바다'));
    await pumpEventQueue();
    await sub.cancel();

    expect(names, ['하늘', '바다']);
  });

  test('삭제하면 points 와 photos 가 cascade 로 사라진다', () async {
    await repository.insert(
      walkOf(
        'w1',
        startedAt: t0,
        withDogs: [named('d1', '하늘')],
        photos: const [WalkPhoto(id: 'p1', path: 'a.jpg', position: 0)],
      ),
      [trackPoint(37.1)],
    );

    await repository.delete('w1');

    expect(await count(db.walks), 0);
    expect(await count(db.walkPoints), 0);
    expect(await count(db.walkPhotos), 0);
    expect(await count(db.walkDogs), 0);
    expect(await count(db.dogs), 2);
  });

  test('getTrack 은 seq 순이다', () async {
    await repository.insert(walkOf('w1', startedAt: t0), [
      trackPoint(37.3),
      trackPoint(37.1),
      trackPoint(37.2),
    ]);

    final track =
        ((await repository.getTrack('w1')) as Ok<List<WalkTrackPoint>>).value;

    expect(track.map((p) => p.point.lat), [37.3, 37.1, 37.2]);
  });

  test('update 는 dogs · photos · memo 만 바꾼다', () async {
    final original = walkOf(
      'w1',
      startedAt: t0,
      withDogs: [named('d1', '하늘')],
      photos: const [WalkPhoto(id: 'p1', path: 'a.jpg', position: 0)],
      memo: '전',
    );
    await repository.insert(original, [trackPoint(37.1)]);

    final later = DateTime(2026, 10, 4);
    await repository.update(
      Walk(
        id: 'w1',
        startedAt: DateTime(2000),
        endedAt: DateTime(2000),
        duration: Duration.zero,
        distanceMeters: 0,
        memo: '후',
        dogs: [named('d2', '가을')],
        photos: const [WalkPhoto(id: 'p9', path: 'z.jpg', position: 0)],
        previewPoints: const [],
        createdAt: t0,
        updatedAt: later,
      ),
    );

    final loaded = ((await repository.findById('w1')) as Ok<Walk?>).value!;
    expect(loaded.memo, '후');
    expect(loaded.updatedAt, later);
    expect(loaded.dogs.map((d) => d.id), ['d2']);
    expect(loaded.photos.map((p) => p.id), ['p9']);
    expect(loaded.startedAt, t0);
    expect(loaded.distanceMeters, 1200.5);
    expect(loaded.previewPoints, isNotEmpty);
    expect(await count(db.walkPoints), 1);
  });

  test('강아지를 지우면 산책은 남고 연결만 끊긴다', () async {
    await repository.insert(
      walkOf('w1', startedAt: t0, withDogs: [named('d1', '하늘')]),
      const [],
    );

    await dogs.delete('d1');

    final loaded = ((await repository.findById('w1')) as Ok<Walk?>).value!;
    expect(loaded.dogs, isEmpty);
    expect(await count(db.walkDogs), 0);
  });

  test('started_at 이 같으면 id 내림차순으로 정렬한다', () async {
    await repository.insert(walkOf('a', startedAt: t0), const []);
    await repository.insert(walkOf('c', startedAt: t0), const []);
    await repository.insert(walkOf('b', startedAt: t0), const []);

    final result = await repository.watchAll().first;

    expect(_walks(result).map((w) => w.id), ['c', 'b', 'a']);
  });
}
