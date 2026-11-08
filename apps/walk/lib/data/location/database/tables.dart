import 'package:drift/drift.dart';

import '../../../domain/location/entity/record_mode.dart';

@DataClassName('LocationPointRow')
@TableIndex(name: 'location_points_recorded_at', columns: {#recordedAt})
class LocationPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get accuracyM => real().nullable()();
  TextColumn get mode => textEnum<RecordMode>()();
  BoolColumn get stillStart => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {recordedAt, lat, lng},
  ];
}

@DataClassName('PlaceNameRow')
class PlaceNames extends Table {
  TextColumn get gridKey => text()();
  TextColumn get name => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {gridKey};
}
