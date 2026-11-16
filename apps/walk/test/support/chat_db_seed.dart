/// 채팅 DB 에 직접 행을 넣는 도우미(백업 영역 테스트용).
library;

import 'package:drift/drift.dart' show Value;
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

final _at = DateTime(2026, 11, 1, 9);

Future<void> insertConversation(
  ChatDatabase db,
  String id, {
  String title = '대화',
}) => db
    .into(db.conversations)
    .insert(
      ConversationsCompanion.insert(
        id: id,
        title: title,
        createdAt: _at,
        updatedAt: _at,
      ),
    );

Future<void> insertTurn(
  ChatDatabase db,
  String conversationId,
  int seq, {
  String attachments = '[]',
  ChatVendor vendor = ChatVendor.anthropic,
}) => db
    .into(db.chatTurns)
    .insert(
      ChatTurnsCompanion.insert(
        conversationId: conversationId,
        seq: seq,
        question: '질문 $seq',
        answer: '답 $seq',
        citedEntryIds: const ['e1'],
        vendor: vendor,
        model: 'm',
        askedAt: _at,
        attachments: Value(attachments),
      ),
    );

Future<void> insertUsage(
  ChatDatabase db, {
  ChatUsagePurpose purpose = ChatUsagePurpose.chat,
}) => db
    .into(db.chatUsageRows)
    .insert(
      ChatUsageRowsCompanion.insert(
        at: _at,
        questionKey: 'q',
        vendor: ChatVendor.anthropic,
        model: 'm',
        purpose: purpose,
        round: 1,
        temporary: false,
        inputTokens: 10,
        outputTokens: 20,
        cacheReadTokens: 0,
        cacheWriteTokens: 0,
      ),
    );

/// [id] 를 지정해 넣는다. 지정하지 않으면 자동 증가.
Future<int> insertWikiNote(
  ChatDatabase db,
  int? id, {
  String? source,
  String title = '메모',
}) => db
    .into(db.wikiNotes)
    .insert(
      WikiNotesCompanion.insert(
        id: id == null ? const Value.absent() : Value(id),
        title: title,
        summary: '요약',
        body: '본문',
        sourceConversationId: Value(source),
        createdAt: _at,
        updatedAt: _at,
      ),
    );
