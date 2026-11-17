import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/suggest/suggest_prompt.dart';

void main() {
  group('parse', () {
    test('번호 · 글머리표 · 따옴표를 떼고 한 줄에 하나씩', () {
      const raw =
          '1. 어제 뭐 했지?\n'
          '- "지난주 걸음 수는?"\n'
          '\n'
          '• 이번 달 일찍 일어난 날은?\n'
          '4) 요즘 자주 간 곳은?\n';

      expect(SuggestPrompt.parse(raw), [
        '어제 뭐 했지?',
        '지난주 걸음 수는?',
        '이번 달 일찍 일어난 날은?',
        '요즘 자주 간 곳은?',
      ]);
    });

    test('40자 넘는 줄 · 중복은 빼고 앞 4개까지', () {
      final long = '가' * 41;
      final raw = ['a?', long, 'b?', 'a?', 'c?', 'd?', 'e?'].join('\n');

      expect(SuggestPrompt.parse(raw), ['a?', 'b?', 'c?', 'd?']);
    });
  });

  test('user 글에 오늘 날짜와 질문 · 물은 날짜가 실리고 긴 질문은 200자로 자른다', () {
    final text = SuggestPrompt.user([
      (question: '어제 뭐 했지?', askedAt: DateTime(2026, 11, 16, 21, 5)),
      (question: '나' * 250, askedAt: DateTime(2026, 11, 10, 8)),
    ], DateTime(2026, 11, 17, 9));

    expect(text, contains('2026-11-17'));
    expect(text, contains('2026-11-16'));
    expect(text, contains('어제 뭐 했지?'));
    expect(text, contains('나' * 200));
    expect(text, isNot(contains('나' * 201)));
  });

  test('system 은 앱 언어로 쓰라고 한다', () {
    expect(SuggestPrompt.system('en'), contains('English'));
    expect(SuggestPrompt.system('ko'), contains('한국어'));
  });
}
