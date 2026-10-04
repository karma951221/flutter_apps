import 'package:drift/drift.dart';

import 'tables.dart';

part 'walk_database.g.dart';

@DriftDatabase(tables: [Dogs, Walks, WalkDogs, WalkPoints, WalkPhotos])
class WalkDatabase extends _$WalkDatabase {
  WalkDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // 꺼져 있으면 ON DELETE CASCADE 가 조용히 동작하지 않는다.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
