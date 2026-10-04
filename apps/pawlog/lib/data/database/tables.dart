import 'package:drift/drift.dart';

@DataClassName('DogRow')
class Dogs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get breed => text().nullable()();

  /// 날짜만 담는 `yyyy-MM-dd`. 시각 컬럼처럼 ISO 전체를 쓰면 시간대에 따라 하루가 밀린다.
  TextColumn get birthday => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WalkRow')
@TableIndex(name: 'walks_started_at', columns: {#startedAt})
class Walks extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  RealColumn get distanceMeters => real()();
  TextColumn get memo => text().nullable()();
  TextColumn get routePreview => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WalkDogRow')
class WalkDogs extends Table {
  TextColumn get walkId =>
      text().references(Walks, #id, onDelete: KeyAction.cascade)();
  TextColumn get dogId =>
      text().references(Dogs, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {walkId, dogId};
}

@DataClassName('WalkPointRow')
class WalkPoints extends Table {
  TextColumn get walkId =>
      text().references(Walks, #id, onDelete: KeyAction.cascade)();
  IntColumn get seq => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get accuracy => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {walkId, seq};
}

@DataClassName('WalkPhotoRow')
@TableIndex(name: 'walk_photos_walk_id', columns: {#walkId})
class WalkPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get walkId =>
      text().references(Walks, #id, onDelete: KeyAction.cascade)();
  TextColumn get path => text()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
