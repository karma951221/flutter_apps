import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';

void main() {
  group('conversationTitleFrom', () {
    test('제목은 첫 질문의 앞 30자이고 넘치면 …', () {
      final question = 'ㄱ' * 40;
      final title = conversationTitleFrom(question);
      expect(title, '${'ㄱ' * 30}…');
    });

    test('줄바꿈 · 연속 공백은 공백 하나로', () {
      expect(conversationTitleFrom('  오늘\n\n  뭐   했지?\t '), '오늘 뭐 했지?');
    });

    test('30자 이하면 그대로, … 없음', () {
      final question = 'a' * conversationTitleMax;
      expect(conversationTitleFrom(question), question);
      expect(conversationTitleFrom('짧은 질문'), '짧은 질문');
    });

    test('이모지 · 한글 조합을 글자 중간에서 자르지 않는다', () {
      // 가족 이모지(여러 코드 포인트)와 조합형 한글(초성+중성)을 grapheme 하나로 센다.
      const family = '👨‍👩‍👧';
      const jamo = '가'; // 가(조합형)
      final question = '$family$jamo' * 20; // 40 글자
      final title = conversationTitleFrom(question);
      expect(title, '${'$family$jamo' * 15}…');
    });
  });

  group('toString 에 질문 · 답 글이 없다', () {
    const secretQ = 'SECRET_QUESTION';
    const secretA = 'SECRET_ANSWER';
    final at = DateTime(2026, 11, 1, 9);

    test('Conversation', () {
      final c = Conversation(
        id: 'c1',
        title: secretQ,
        titleEdited: false,
        createdAt: at,
        updatedAt: at,
        turnCount: 3,
      );
      final s = c.toString();
      expect(s, isNot(contains(secretQ)));
      expect(s, contains('c1'));
      expect(s, contains('turns: 3'));
    });

    test('ChatTurnRecord', () {
      final r = ChatTurnRecord(
        conversationId: 'c1',
        seq: 2,
        question: secretQ,
        answer: secretA,
        citedEntryIds: const ['e1'],
        stopped: false,
        vendor: ChatVendor.anthropic,
        model: 'm',
        askedAt: at,
      );
      final s = r.toString();
      expect(s, isNot(contains(secretQ)));
      expect(s, isNot(contains(secretA)));
      expect(s, contains('seq: 2'));
      expect(s, contains('answerLength: ${secretA.length}'));
      expect(r.text, const ChatTurnText(question: secretQ, answer: secretA));
    });

    test('ChatTurnDraft', () {
      const d = ChatTurnDraft(
        question: secretQ,
        answer: secretA,
        citedEntryIds: [],
        vendor: ChatVendor.openai,
        model: 'm',
      );
      final s = d.toString();
      expect(s, isNot(contains(secretQ)));
      expect(s, isNot(contains(secretA)));
      expect(d.stopped, isFalse);
    });

    test('ChatTurnText', () {
      const t = ChatTurnText(question: secretQ, answer: secretA, stopped: true);
      final s = t.toString();
      expect(s, isNot(contains(secretQ)));
      expect(s, isNot(contains(secretA)));
      expect(s, contains('stopped: true'));
    });
  });
}
