import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/tool/tool_input.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';

void main() {
  group('toolRange', () {
    test('최대 일수를 넘으면 to 기준으로 자르고 clamped', () {
      final r = toolRange({'from': '2026-01-01', 'to': '2026-03-01'}, maxDays: 31)!;
      expect(r.from, DateTime(2026, 1, 30));
      expect(r.to, DateTime(2026, 3, 1));
      expect(r.clamped, isTrue);
      expect(r.clampJson, {'clamped': true});
    });

    test('범위 안이면 그대로', () {
      final r = toolRange({'from': '2026-03-01', 'to': '2026-03-01'}, maxDays: 31)!;
      expect(r.from, DateTime(2026, 3, 1));
      expect(r.clamped, isFalse);
      expect(r.clampJson, isEmpty);
      expect(r.end, DateTime(2026, 3, 1, 23, 59, 59, 999));
    });

    test('from 이 to 뒤 · 없는 날짜 · 형식 틀림은 null', () {
      expect(toolRange({'from': '2026-03-02', 'to': '2026-03-01'}, maxDays: 31), isNull);
      expect(toolRange({'from': '2026-02-30', 'to': '2026-03-01'}, maxDays: 31), isNull);
      expect(toolRange({'from': '2026/03/01', 'to': '2026-03-01'}, maxDays: 31), isNull);
      expect(toolRange({'to': '2026-03-01'}, maxDays: 31), isNull);
    });
  });

  test('parseToolDate 는 앞뒤 공백을 허용한다', () {
    expect(parseToolDate(' 2026-03-04 '), DateTime(2026, 3, 4));
    expect(parseToolDate(3), isNull);
  });

  test('toolDay · toolTime', () {
    expect(toolDay(DateTime(2026, 3, 4, 7, 5)), '2026-03-04');
    expect(toolTime(DateTime(2026, 3, 4, 7, 5)), '07:05');
  });

  test('toolError 는 오류 json 과 오류 요약', () {
    final r = toolError('invalid_range', ChatToolKind.dailySteps);
    expect(r.isError, isTrue);
    expect(jsonDecode(r.json), {'error': 'invalid_range'});
    expect(r.summary?.kind, ChatToolKind.dailySteps);
    expect(r.summary?.isError, isTrue);
    expect(r.summary?.count, 0);
  });
}
