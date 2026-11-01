import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/chat/chat_usage_log.dart';
import '../../../domain/chat/chat_vendor.dart';

/// 인용한 일기 id 목록을 JSON 배열 글로 둔다.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<Object?>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

@DataClassName('ConversationRow')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get titleEdited => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ChatTurnRow')
class ChatTurns extends Table {
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: KeyAction.cascade)();
  IntColumn get seq => integer()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get citedEntryIds => text().map(const StringListConverter())();
  BoolColumn get stopped => boolean().withDefault(const Constant(false))();
  TextColumn get vendor => textEnum<ChatVendor>()();
  TextColumn get model => text()();
  DateTimeColumn get askedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {conversationId, seq};
}

/// 요청(도구 라운드) 하나의 토큰 사용량. 쓰기 · 읽기는 Task 2.
@DataClassName('ChatUsageRow')
@TableIndex(name: 'chat_usage_at', columns: {#at})
class ChatUsageRows extends Table {
  @override
  String get tableName => 'chat_usage';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get questionKey => text()();
  TextColumn get vendor => textEnum<ChatVendor>()();
  TextColumn get model => text()();
  BoolColumn get fastMode => boolean().withDefault(const Constant(false))();
  TextColumn get purpose => textEnum<ChatUsagePurpose>()();
  IntColumn get round => integer()();
  BoolColumn get temporary => boolean()();
  IntColumn get inputTokens => integer()();
  IntColumn get outputTokens => integer()();
  IntColumn get cacheReadTokens => integer()();
  IntColumn get cacheWriteTokens => integer()();
  IntColumn get reasoningTokens => integer().nullable()();
  IntColumn get wikiIndexNotes => integer().withDefault(const Constant(0))();
  IntColumn get wikiIndexChars => integer().withDefault(const Constant(0))();
  IntColumn get readWikiCalls => integer().withDefault(const Constant(0))();
}
