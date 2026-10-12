import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/diary/widget/highlighted_text.dart';

/// 굵게 그려진 조각만 모은다.
List<String> boldParts(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byType(HighlightedText),
      matching: find.byType(Text),
    ),
  );
  final parts = <String>[];
  text.textSpan!.visitChildren((span) {
    if (span is TextSpan && span.style?.fontWeight == FontWeight.bold) {
      parts.add(span.text!);
    }
    return true;
  });
  return parts;
}

void main() {
  group('matchRanges', () {
    test('영문은 대소문자를 가리지 않고 모든 일치를 찾는다', () {
      expect(matchRanges('Jeju jeju JEJU', 'jEJu'), [(0, 4), (5, 9), (10, 14)]);
    });

    test('한글 · 이모지 · 특수문자(%, _, \\)도 글자 그대로 찾는다', () {
      expect(matchRanges('🌊 바다 100%_\\', '바다'), [(3, 5)]);
      expect(matchRanges('🌊 바다 100%_\\', '%_\\'), [(9, 12)]);
    });

    test('겹치지 않게 앞에서부터, 빈 검색어는 일치 없음', () {
      expect(matchRanges('aaaa', 'aa'), [(0, 2), (2, 4)]);
      expect(matchRanges('abc', ''), isEmpty);
    });
  });

  group('matchSnippet', () {
    test('짧은 본문은 줄바꿈만 공백으로 바꾼다', () {
      expect(matchSnippet('아침에\n바다를  봤다', '바다'), '아침에 바다를 봤다');
    });

    test('긴 본문은 첫 일치 조금 앞에서 자르고 … 를 붙인다', () {
      final body = '${'가' * 10000}바다';
      final snippet = matchSnippet(body, '바다', lead: 5);
      expect(snippet, '…가가가가가바다');
    });

    test('자르는 자리가 이모지 가운데면 이모지를 깨지 않는다', () {
      final body = '${'가' * 50}🌊바다';
      final snippet = matchSnippet(body, '바다', lead: 1);
      expect(snippet, '…🌊바다');
    });
  });

  testWidgets('일치한 부분만 굵게 그린다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HighlightedText('Seoul 서울 seoul', query: 'SEOUL'),
      ),
    );

    expect(boldParts(tester), ['Seoul', 'seoul']);
    expect(find.text('Seoul 서울 seoul'), findsOneWidget);
  });
}
