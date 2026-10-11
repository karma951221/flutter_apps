import 'package:drift/drift.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';
import 'tables.dart';

part 'diary_database.g.dart';

@DriftDatabase(tables: [Stories, Places, Tags, Entries, Media, EntryTags])
class DiaryDatabase extends _$DiaryDatabase {
  /// [now] 는 기본 스토리의 시각을 정한다. 테스트는 고정 함수를 넘긴다.
  DiaryDatabase(super.executor, {required DateTime Function() now})
    : _now = now;

  final DateTime Function() _now;

  @override
  int get schemaVersion => 1;

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      // 꺼져 있으면 ON DELETE CASCADE 가 조용히 동작하지 않는다.
      await customStatement('PRAGMA foreign_keys = ON');
      // 처음 만들 때뿐 아니라 지워졌을 때도 되살린다. 기본 스토리가 없으면
      // 기록을 둘 곳이 없다.
      await _ensureDailyStory();
    },
  );

  Future<void> _ensureDailyStory() {
    final now = _now();
    return into(stories).insert(
      StoriesCompanion.insert(
        id: Story.dailyId,
        title: '',
        status: StoryStatus.open,
        startedAt: now,
        createdAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}
