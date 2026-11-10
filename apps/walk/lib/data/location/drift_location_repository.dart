import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/location/entity/location_point.dart';
import '../../domain/location/repository/location_repository.dart';
import 'database/location_database.dart';

/// 시각은 UTC 로 저장하고 현지로 돌려준다.
@LazySingleton(as: LocationRepository)
class DriftLocationRepository implements LocationRepository {
  DriftLocationRepository(this._db, this._clock);

  final LocationDatabase _db;
  final Clock _clock;

  @override
  Future<int> insertAll(List<LocationPoint> points) async {
    if (points.isEmpty) return 0;
    return _db.transaction(() async {
      final before = await _count();
      await _db.batch((b) {
        b.insertAll(_db.locationPoints, [
          for (final p in points)
            LocationPointsCompanion.insert(
              recordedAt: p.recordedAt.toUtc(),
              lat: p.lat,
              lng: p.lng,
              accuracyM: Value(p.accuracyM),
              mode: p.mode,
              stillStart: Value(p.stillStart),
            ),
        ], mode: InsertMode.insertOrIgnore);
      });
      return await _count() - before;
    });
  }

  Future<int> _count() async {
    final count = _db.locationPoints.id.count();
    final query = _db.selectOnly(_db.locationPoints)..addColumns([count]);
    return (await query.map((r) => r.read(count)).getSingle()) ?? 0;
  }

  @override
  Future<List<LocationPoint>> pointsBetween(DateTime from, DateTime to) async {
    final rows =
        await (_db.select(_db.locationPoints)
              ..where(
                (t) => t.recordedAt.isBetweenValues(from.toUtc(), to.toUtc()),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
            .get();
    return [for (final r in rows) _toPoint(r)];
  }

  @override
  Future<List<LocationPoint>> pointsAround(DateTime from, DateTime to) =>
      _db.transaction(() async {
        final before =
            await (_db.select(_db.locationPoints)
                  ..where((t) => t.recordedAt.isSmallerThanValue(from.toUtc()))
                  ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
                  ..limit(1))
                .getSingleOrNull();
        final inside = await pointsBetween(from, to);
        final after =
            await (_db.select(_db.locationPoints)
                  ..where((t) => t.recordedAt.isBiggerThanValue(to.toUtc()))
                  ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)])
                  ..limit(1))
                .getSingleOrNull();
        return [
          if (before != null) _toPoint(before),
          ...inside,
          if (after != null) _toPoint(after),
        ];
      });

  LocationPoint _toPoint(LocationPointRow r) => LocationPoint(
    recordedAt: r.recordedAt.toLocal(),
    lat: r.lat,
    lng: r.lng,
    accuracyM: r.accuracyM,
    mode: r.mode,
    stillStart: r.stillStart,
  );

  @override
  Future<bool> hasAnyPoint() async {
    final row = await (_db.select(
      _db.locationPoints,
    )..limit(1)).getSingleOrNull();
    return row != null;
  }

  @override
  Future<int> purgeBefore(DateTime cutoff) => (_db.delete(
    _db.locationPoints,
  )..where((t) => t.recordedAt.isSmallerThanValue(cutoff.toUtc()))).go();

  @override
  Future<void> deleteAll() => _db.transaction(() async {
    await _db.delete(_db.locationPoints).go();
    await _db.delete(_db.placeNames).go();
  });

  @override
  Future<String?> placeName(String gridKey) async {
    final row = await (_db.select(
      _db.placeNames,
    )..where((t) => t.gridKey.equals(gridKey))).getSingleOrNull();
    return row?.name;
  }

  @override
  Future<void> savePlaceName(String gridKey, String name) => _db
      .into(_db.placeNames)
      .insertOnConflictUpdate(
        PlaceNamesCompanion.insert(
          gridKey: gridKey,
          name: name,
          updatedAt: _clock.now().toUtc(),
        ),
      );
}
