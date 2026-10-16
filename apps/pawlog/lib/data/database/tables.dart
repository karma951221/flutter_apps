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

/// 진행 중 산책 한 건(언제나 id 1). 앱이 죽어도 이어 가려고 쓴다.
/// 외래 키가 없다 — 진행 중에 반려견이 지워져도 남고, 저장할 때 있는 반려견만 붙인다.
@DataClassName('ActiveWalkRow')
class ActiveWalks extends Table {
  IntColumn get id => integer()();

  /// JSON 배열.
  TextColumn get dogIds => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get pausedMs => integer()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  RealColumn get distanceMeters => real()();
  TextColumn get noticeTitle => text()();
  TextColumn get noticeText => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActiveWalkPointRow')
class ActiveWalkPoints extends Table {
  IntColumn get seq => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get accuracy => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {seq};
}
