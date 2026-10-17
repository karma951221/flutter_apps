import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/database/walk_database.dart';
import 'package:pawlog/data/dog/drift_dog_repository.dart';
import 'package:pawlog/data/walk/drift_walk_repository.dart';
import 'package:pawlog/domain/dog/entity/dog.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/domain/walk/entity/walk_photo.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';

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
    bool isFavorite = false,
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
    isFavorite: isFavorite,
  );

  Future<Walk> load(String id) async =>
      ((await repository.findById(id)) as Ok<Walk?>).value!;

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

  group('즐겨찾기', () {
    test('insert 는 isFavorite 를 저장한다', () async {
      await repository.insert(
        walkOf('w1', startedAt: t0, isFavorite: true),
        const [],
      );

      expect((await load('w1')).isFavorite, isTrue);
    });

    test('setFavorite 로 켜고 끈 값이 findById · watchAll 에 보인다', () async {
      await repository.insert(walkOf('w1', startedAt: t0), const []);

      expect(await repository.setFavorite('w1', true), isA<Ok<void>>());
      expect((await load('w1')).isFavorite, isTrue);
      expect(
        _walks(await repository.watchAll().first).single.isFavorite,
        isTrue,
      );

      expect(await repository.setFavorite('w1', false), isA<Ok<void>>());
      expect((await load('w1')).isFavorite, isFalse);
      expect(
        _walks(await repository.watchAll().first).single.isFavorite,
        isFalse,
      );
    });

    test('setFavorite 는 updatedAt 을 바꾸지 않는다', () async {
      await repository.insert(walkOf('w1', startedAt: t0), const []);

      await repository.setFavorite('w1', true);

      expect((await load('w1')).updatedAt, t0);
    });

    test('없는 id 면 Err(notFound · walkNotFound)', () async {
      final result = await repository.setFavorite('missing', true);

      expect(result, isA<Err<void>>());
      expect(
        (result as Err<void>).failure,
        isA<NotFoundFailure>().having(
          (f) => f.failureCode,
          'failureCode',
          FailureCode.walkNotFound,
        ),
      );
    });

    test('update 는 즐겨찾기를 지우지 않는다', () async {
      await repository.insert(
        walkOf('w1', startedAt: t0, isFavorite: true),
        const [],
      );

      await repository.update(walkOf('w1', startedAt: t0, memo: '수정'));

      final loaded = await load('w1');
      expect(loaded.memo, '수정');
      expect(loaded.isFavorite, isTrue);
    });
  });

  group('watchRecent', () {
    // w0 이 가장 오래, w4 가 가장 최근. 산책마다 반려견 둘 · 사진 둘.
    Future<void> seedFive({Set<String> favorites = const {}}) async {
      for (var i = 0; i < 5; i++) {
        await repository.insert(
          walkOf(
            'w$i',
            startedAt: DateTime(2026, 10, 1 + i, 9),
            withDogs: [named('d1', '하늘'), named('d2', '가을')],
            photos: [
              WalkPhoto(id: 'w$i-p0', path: 'w$i-0.jpg', position: 0),
              WalkPhoto(id: 'w$i-p1', path: 'w$i-1.jpg', position: 1),
            ],
            isFavorite: favorites.contains('w$i'),
          ),
          const [],
        );
      }
    }

    test('조인 행이 아니라 산책 수로 자르고, 최신순에 반려견 · 사진을 모두 싣는다', () async {
      await seedFive();

      final result = _walks(await repository.watchRecent(limit: 3).first);

      expect(result.map((w) => w.id), ['w4', 'w3', 'w2']);
      for (final walk in result) {
        expect(walk.dogs.map((d) => d.id), unorderedEquals(['d1', 'd2']));
        expect(walk.photos.map((p) => p.position), [0, 1]);
      }
    });

    test('favoritesOnly 면 즐겨찾기만, 그래도 limit 을 지킨다', () async {
      await seedFive(favorites: {'w0', 'w2', 'w3'});

      final result = _walks(
        await repository.watchRecent(limit: 2, favoritesOnly: true).first,
      );

      expect(result.map((w) => w.id), ['w3', 'w2']);
      expect(result.every((w) => w.isFavorite), isTrue);
    });

    test('started_at 이 같으면 id 내림차순이다', () async {
      await repository.insert(walkOf('a', startedAt: t0), const []);
      await repository.insert(walkOf('b', startedAt: t0), const []);

      final result = _walks(await repository.watchRecent(limit: 1).first);

      expect(result.map((w) => w.id), ['b']);
    });

    test('더 최근 산책을 넣으면 그 산책을 맨 앞에 두고 다시 흐른다', () async {
      await seedFive();
      final emitted = <List<String>>[];
      final sub = repository
          .watchRecent(limit: 3)
          .listen((r) => emitted.add([for (final w in _walks(r)) w.id]));
      await pumpEventQueue();

      await repository.insert(
        walkOf('newest', startedAt: DateTime(2026, 10, 9, 9)),
        const [],
      );
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted.first, ['w4', 'w3', 'w2']);
      expect(emitted.last, ['newest', 'w4', 'w3']);
    });
  });

  group('watchStartedSince', () {
    test('from 이후(같은 시각 포함)에 시작한 산책만 반려견 · 사진과 함께 낸다', () async {
      final from = DateTime(2026, 10, 5);
      await repository.insert(
        walkOf('before', startedAt: from.subtract(const Duration(minutes: 1))),
        const [],
      );
      await repository.insert(
        walkOf('at', startedAt: from, withDogs: [named('d1', '하늘')]),
        const [],
      );
      await repository.insert(
        walkOf('after', startedAt: DateTime(2026, 10, 6, 9)),
        const [],
      );

      final result = _walks(await repository.watchStartedSince(from).first);

      expect(result.map((w) => w.id), ['after', 'at']);
      expect(result.last.dogs.single.id, 'd1');
    });
  });
}
