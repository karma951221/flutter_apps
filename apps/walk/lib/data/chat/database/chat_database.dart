import 'package:drift/drift.dart';

import '../../../domain/chat/chat_usage_log.dart';
import '../../../domain/chat/chat_vendor.dart';
import 'chat_tables.dart';

part 'chat_database.g.dart';

@DriftDatabase(tables: [Conversations, ChatTurns, ChatUsageRows])
class ChatDatabase extends _$ChatDatabase {
  ChatDatabase(super.e);

  /// 1: conversations · chat_turns · chat_usage. 2(위키 단계): wiki_notes 를 더한다 —
  /// onUpgrade 의 `if (from < 2)` 자리와 drift_schemas/chat/ 의 v1 덤프로 migration 테스트를 만든다.
  @override
  int get schemaVersion => 1;

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // 2단계: if (from < 2) await m.createTable(wikiNotes);
    },
    // 꺼져 있으면 대화를 지울 때 턴이 cascade 로 지워지지 않는다.
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
