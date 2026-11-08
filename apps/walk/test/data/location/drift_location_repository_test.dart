import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/location/database/location_database.dart';
import 'package:walk/data/location/drift_location_repository.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';

LocationPoint _p(
  int minute, {
  double lat = 37.5,
  double lng = 127.0,
  bool stillStart = false,
}) => LocationPoint(
  recordedAt: DateTime.utc(2026, 11, 8, 9, minute),
  lat: lat,
  lng: lng,
  accuracyM: 12,
  mode: RecordMode.normal,
  stillStart: stillStart,
);

void main() {
  late LocationDatabase db;
  late DriftLocationRepository repo;

  setUp(() {
    db = LocationDatabase(NativeDatabase.memory());
    repo = DriftLocationRepository(db, const Clock());
  });
  tearDown(() => db.close());

  test('insertAll ignores duplicates', () async {
    final points = [_p(0), _p(1), _p(2)];

    expect(await repo.insertAll(points), 3);
    expect(await repo.insertAll(points), 0);

    final all = await repo.pointsBetween(
      DateTime.utc(2026, 11, 8),
      DateTime.utc(2026, 11, 9),
    );
    expect(all, hasLength(3));
  });

  test('stillStart round trip', () async {
    await repo.insertAll([_p(0, stillStart: true), _p(1)]);

    final all = await repo.pointsBetween(
      DateTime.utc(2026, 11, 8),
      DateTime.utc(2026, 11, 9),
    );
    expect(all.map((p) => p.stillStart), [true, false]);
    expect(all.first.mode, RecordMode.normal);
    expect(all.first.accuracyM, 12);
    expect(
      all.first.recordedAt.isAtSameMomentAs(DateTime.utc(2026, 11, 8, 9)),
      isTrue,
    );
    expect(all.first.recordedAt.isUtc, isFalse);
  });

  test('pointsBetween is inclusive and ordered', () async {
    await repo.insertAll([_p(30), _p(10), _p(20), _p(40), _p(5)]);

    final got = await repo.pointsBetween(
      DateTime.utc(2026, 11, 8, 9, 10),
      DateTime.utc(2026, 11, 8, 9, 30),
    );

    expect(got.map((p) => p.recordedAt.toUtc().minute), [10, 20, 30]);
  });

  test('purgeBefore deletes older points only', () async {
    await repo.insertAll([_p(0), _p(10), _p(20)]);

    final deleted = await repo.purgeBefore(DateTime.utc(2026, 11, 8, 9, 10));

    expect(deleted, 1);
    final left = await repo.pointsBetween(
      DateTime.utc(2026, 11, 8),
      DateTime.utc(2026, 11, 9),
    );
    expect(left.map((p) => p.recordedAt.toUtc().minute), [10, 20]);
  });

  test('deleteAll clears points and place names', () async {
    await repo.insertAll([_p(0)]);
    await repo.savePlaceName('37.500,127.000', '집');

    await repo.deleteAll();

    expect(await repo.hasAnyPoint(), isFalse);
    expect(await repo.placeName('37.500,127.000'), isNull);
  });

  test('placeName round trip', () async {
    expect(await repo.placeName('k'), isNull);

    await repo.savePlaceName('k', '카페');
    expect(await repo.placeName('k'), '카페');

    await repo.savePlaceName('k', '회사');
    expect(await repo.placeName('k'), '회사');
  });

  test('hasAnyPoint', () async {
    expect(await repo.hasAnyPoint(), isFalse);

    await repo.insertAll([_p(0)]);

    expect(await repo.hasAnyPoint(), isTrue);
  });
}
