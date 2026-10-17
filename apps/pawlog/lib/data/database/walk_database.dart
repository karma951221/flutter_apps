import 'package:drift/drift.dart';

import 'tables.dart';

part 'walk_database.g.dart';

@DriftDatabase(
  tables: [
    Dogs,
    Walks,
    WalkDogs,
    WalkPoints,
    WalkPhotos,
    ActiveWalks,
    ActiveWalkPoints,
  ],
)
class WalkDatabase extends _$WalkDatabase {
  WalkDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: 진행 중 산책 복구. 기존 다섯 테이블은 그대로 둔다.
      if (from < 2) {
        await m.createTable(activeWalks);
        await m.createTable(activeWalkPoints);
      }
      // v3: 산책 즐겨찾기. 기존 행은 기본값 false 로 채워진다.
      if (from < 3) {
        await m.addColumn(walks, walks.isFavorite);
      }
    },
    // 꺼져 있으면 ON DELETE CASCADE 가 조용히 동작하지 않는다.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
