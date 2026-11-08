import 'package:drift/drift.dart';

import '../../../domain/location/entity/record_mode.dart';
import 'tables.dart';

part 'location_database.g.dart';

@DriftDatabase(tables: [LocationPoints, PlaceNames])
class LocationDatabase extends _$LocationDatabase {
  LocationDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
