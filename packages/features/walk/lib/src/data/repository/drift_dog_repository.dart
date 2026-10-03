import 'dart:async';

import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/dog.dart';
import '../../domain/repository/dog_repository.dart';
import '../database/walk_database.dart';
import '../database/walk_mapper.dart';

@LazySingleton(as: DogRepository)
class DriftDogRepository implements DogRepository {
  DriftDogRepository(this._db);

  final WalkDatabase _db;

  SimpleSelectStatement<$DogsTable, DogRow> _byName() =>
      _db.select(_db.dogs)..orderBy([(t) => OrderingTerm.asc(t.name)]);

  /// 오류를 예외로 흘리면 구독이 끊기므로 값(`Err`)으로 바꿔 흘린다.
  @override
  Stream<Result<List<Dog>>> watchAll() => _byName().watch().transform(
    StreamTransformer<List<DogRow>, Result<List<Dog>>>.fromHandlers(
      handleData: (rows, sink) =>
          sink.add(Ok([for (final r in rows) dogFromRow(r)])),
      handleError: (error, _, sink) =>
          sink.add(Err(Failure.unknown(message: error.toString()))),
    ),
  );

  @override
  Future<Result<List<Dog>>> getAll() async {
    try {
      final rows = await _byName().get();
      return Ok([for (final r in rows) dogFromRow(r)]);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<Result<Dog?>> findById(String id) async {
    try {
      final row = await (_db.select(
        _db.dogs,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      return Ok(row == null ? null : dogFromRow(row));
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<Result<void>> upsert(Dog dog) async {
    try {
      await _db.into(_db.dogs).insertOnConflictUpdate(dogToCompanion(dog));
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await (_db.delete(_db.dogs)..where((t) => t.id.equals(id))).go();
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }
}
