import 'package:drift/drift.dart';

import '../../../domain/alarm/entity/ring_log_entry.dart';

part 'ring_archive_database.g.dart';

@DataClassName('ArchivedRingRow')
class ArchivedRings extends Table {
  DateTimeColumn get at => dateTime()();
  IntColumn get packageId => integer()();
  TextColumn get kind => textEnum<RingLogKind>()();
  TextColumn get label => text().nullable()();
  IntColumn get hour => integer().nullable()();
  IntColumn get minute => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {at, packageId, kind};
}

@DriftDatabase(tables: [ArchivedRings])
class RingArchiveDatabase extends _$RingArchiveDatabase {
  RingArchiveDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
