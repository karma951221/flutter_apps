import 'package:drift/drift.dart';

import '../../../domain/chat/chat_usage_log.dart';
import '../../../domain/chat/chat_vendor.dart';
import 'chat_tables.dart';

part 'chat_database.g.dart';

@DriftDatabase(tables: [Conversations, ChatTurns, ChatUsageRows, WikiNotes])
class ChatDatabase extends _$ChatDatabase {
  ChatDatabase(super.e);

  /// 1: conversations · chat_turns · chat_usage. 2(위키 단계): wiki_notes 를 더한다.
  /// 3(첨부): chat_turns.attachments(첨부 ref JSON)를 더한다.
  /// drift_schemas/chat/ 에 버전마다 덤프를 두고, 그 덤프에서 만든
  /// test/data/chat/database/generated/ 의 도우미로 migration 테스트를 한다.
  ///
  /// 덤프 만들기: 저장소 lock 의 drift_dev 2.34.0 은 drift 2.34.4 와 컴파일이 안 되고
  /// (`dart run drift_dev schema dump` 실패), 새 drift_dev 는 analyzer ≥13 이 필요해
  /// freezed 3.2.5(analyzer <11)와 함께 못 올린다. 그래서 drift · drift_dev 를 2.34.0 으로
  /// 고정한 임시 패키지에 이 파일 · chat_tables.dart · chat_database.g.dart ·
  /// domain/chat/{chat_vendor,chat_usage_log(.freezed)}.dart · apps/walk/build.yaml 을 같은
  /// 경로로 복사한 뒤 거기서
  /// `dart run drift_dev schema dump lib/data/chat/database/chat_database.dart drift_schemas/chat/`
  /// 를 돌려 나온 JSON 을 apps/walk/drift_schemas/chat/ 에 둔다. 결과의
  /// `store_date_time_values_as_text` 가 true(날짜 열 TEXT)인지 확인한다.
  /// 같은 임시 패키지에서
  /// `dart run drift_dev schema generate --data-classes --companions drift_schemas/chat/ test/data/chat/database/generated/`
  /// 로 도우미(schema.dart · schema_vN.dart)를 만들어 옮긴다. 도우미는 drift 2.34.4 와
  /// 컴파일되지만 drift_dev 의 SchemaVerifier(api/migrations_native.dart)는 안 되어서,
  /// migration 테스트는 도우미로 옛 DB 를 만들고 PRAGMA 로 스키마를 비교한다.
  /// (임시 패키지에서는 SchemaVerifier.migrateAndValidate 로도 한 번 확인한다.)
  @override
  int get schemaVersion => 3;

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // 둘 사이에서 앱이 죽어도 반쯤 올라간 채로 남지 않게 한 트랜잭션.
        await transaction(() async {
          await m.createTable(wikiNotes);
          await m.createIndex(wikiNotesUpdatedAt);
        });
      }
      if (from < 3) {
        await m.addColumn(chatTurns, chatTurns.attachments);
      }
    },
    // 꺼져 있으면 대화를 지울 때 턴이 cascade 로 지워지지 않는다.
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
