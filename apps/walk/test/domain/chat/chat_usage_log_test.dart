import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

void main() {
  test('ChatUsageRecord.toString 에 글 필드가 없다', () {
    final record = ChatUsageRecord(
      at: DateTime(2026, 11, 1),
      questionKey: 'q-1',
      vendor: ChatVendor.anthropic,
      model: 'm',
      fastMode: false,
      purpose: ChatUsagePurpose.chat,
      round: 1,
      temporary: false,
      inputTokens: 10,
      outputTokens: 5,
      cacheReadTokens: 0,
      cacheWriteTokens: 0,
    );

    final text = record.toString();
    final fields = RegExp(
      r'(\w+): ',
    ).allMatches(text).map((m) => m.group(1)).toSet();

    expect(fields, {
      'at',
      'questionKey',
      'vendor',
      'model',
      'fastMode',
      'purpose',
      'round',
      'temporary',
      'inputTokens',
      'outputTokens',
      'cacheReadTokens',
      'cacheWriteTokens',
      'reasoningTokens',
      'wikiIndexNotes',
      'wikiIndexChars',
      'readWikiCalls',
    });
  });
}
