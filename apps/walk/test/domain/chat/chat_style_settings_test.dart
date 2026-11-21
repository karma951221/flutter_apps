import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_style_settings.dart';

void main() {
  group('ChatTone.instruction', () {
    test('기본은 null, 나머지는 말투 문장', () {
      expect(ChatTone.standard.instruction('무시'), isNull);
      expect(ChatTone.warm.instruction(''), contains('존댓말'));
      expect(ChatTone.casual.instruction(''), contains('반말'));
      expect(ChatTone.terse.instruction(''), contains('짧고 건조하게'));
    });

    test('직접 입력은 적은 한 줄, 비면 null', () {
      expect(
        ChatTone.custom.instruction('  해적처럼\n말해  '),
        '말투는 사용자가 정한 대로: "해적처럼 말해".',
      );
      expect(ChatTone.custom.instruction('   '), isNull);
    });
  });

  test('normalizeCustom 은 공백을 접고 글자 수를 자른다', () {
    expect(ChatTone.normalizeCustom(' a \n\t b '), 'a b');
    final long = '가' * (ChatTone.maxCustomChars + 10);
    expect(
      ChatTone.normalizeCustom(long).runes.length,
      ChatTone.maxCustomChars,
    );
  });
}
