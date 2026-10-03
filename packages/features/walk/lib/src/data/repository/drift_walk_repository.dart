import 'dart:async';

import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/walk.dart';
import '../../domain/entity/walk_track_point.dart';
import '../../domain/repository/walk_repository.dart';
import '../database/walk_database.dart';
import '../database/walk_mapper.dart';

@LazySingleton(as: WalkRepository)
class DriftWalkRepository implements WalkRepository {
  DriftWalkRepository(this._db);

  final WalkDatabase _db;

  /// walks ⟕ walk_dogs ⟕ dogs ⟕ walk_photos. 조인해야 dogs 변경에도 watch 가 다시 흐른다.
  JoinedSelectStatement<HasResultSet, dynamic> _joined() {
    final query = _db.select(_db.walks).join([
      leftOuterJoin(_db.walkDogs, _db.walkDogs.walkId.equalsExp(_db.walks.id)),
      leftOuterJoin(_db.dogs, _db.dogs.id.equalsExp(_db.walkDogs.dogId)),
      leftOuterJoin(
        _db.walkPhotos,
        _db.walkPhotos.walkId.equalsExp(_db.walks.id),
      ),
    ]);
    query.orderBy([
      OrderingTerm.desc(_db.walks.startedAt),
      OrderingTerm.desc(_db.walks.id),
      OrderingTerm.asc(_db.walkPhotos.position),
    ]);
    return query;
  }

  List<Walk> _group(List<TypedResult> rows) => walksFromJoinRows([
    for (final r in rows)
      (
        walk: r.readTable(_db.walks),
        dog: r.readTableOrNull(_db.dogs),
        photo: r.readTableOrNull(_db.walkPhotos),
      ),
  ]);

  @override
  Stream<Result<List<Walk>>> watchAll() => _joined().watch().transform(
    StreamTransformer<List<TypedResult>, Result<List<Walk>>>.fromHandlers(
      handleData: (rows, sink) {
        try {
          sink.add(Ok(_group(rows)));
        } catch (error) {
          sink.add(Err(Failure.unknown(message: error.toString())));
        }
      },
      handleError: (error, _, sink) =>
          sink.add(Err(Failure.unknown(message: error.toString()))),
    ),
  );

  @override
  Future<Result<Walk?>> findById(String id) async {
    try {
      final rows = await (_joined()..where(_db.walks.id.equals(id))).get();
      final walks = _group(rows);
      return Ok(walks.isEmpty ? null : walks.first);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<Result<List<WalkTrackPoint>>> getTrack(String id) async {
    try {
      final rows =
          await (_db.select(_db.walkPoints)
                ..where((t) => t.walkId.equals(id))
                ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
              .get();
      return Ok([for (final r in rows) trackPointFromRow(r)]);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<Result<void>> insert(Walk walk, List<WalkTrackPoint> track) async {
    try {
      await _db.transaction(() async {
        await _db.into(_db.walks).insert(walkToCompanion(walk));
        await _insertDogsAndPhotos(walk, walk.createdAt);
        await _db.batch((b) {
          b.insertAll(_db.walkPoints, [
            for (var i = 0; i < track.length; i++)
              trackPointToCompanion(walk.id, i, track[i]),
          ]);
        });
      });
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<Result<void>> update(Walk walk) async {
    try {
      await _db.transaction(() async {
        await (_db.update(_db.walks)..where((t) => t.id.equals(walk.id))).write(
          WalksCompanion(
            memo: Value(walk.memo),
            updatedAt: Value(walk.updatedAt),
          ),
        );
        await (_db.delete(
          _db.walkDogs,
        )..where((t) => t.walkId.equals(walk.id))).go();
        await (_db.delete(
          _db.walkPhotos,
        )..where((t) => t.walkId.equals(walk.id))).go();
        await _insertDogsAndPhotos(walk, walk.updatedAt);
      });
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      // walk_dogs · walk_points · walk_photos 는 FK cascade 로 함께 지워진다.
      await (_db.delete(_db.walks)..where((t) => t.id.equals(id))).go();
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  Future<void> _insertDogsAndPhotos(Walk walk, DateTime photoCreatedAt) async {
    await _db.batch((b) {
      b.insertAll(_db.walkDogs, [
        for (final dog in walk.dogs)
          WalkDogsCompanion.insert(walkId: walk.id, dogId: dog.id),
      ]);
      b.insertAll(_db.walkPhotos, [
        for (final photo in walk.photos)
          photoToCompanion(walk.id, photo, photoCreatedAt),
      ]);
    });
  }
}
