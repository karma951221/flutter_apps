import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/chat/workspace/format/reveal_invisible.dart';

void main() {
  test('방향 바꾸는 글자 · 폭 없는 글자를 드러내고 줄바꿈 · 탭은 그대로 둔다', () {
    expect(revealInvisible('a\u202Eb\u200Bc\n\td'), 'a⟨U+202E⟩b⟨U+200B⟩c\n\td');
  });

  test('제어 문자 · DEL · BOM 을 드러낸다', () {
    expect(revealInvisible('\u0007'), '⟨U+0007⟩');
    expect(revealInvisible('\u0000x\u001F'), '⟨U+0000⟩x⟨U+001F⟩');
    expect(revealInvisible('\r\n'), '⟨U+000D⟩\n');
    expect(revealInvisible('\u007F'), '⟨U+007F⟩');
    expect(revealInvisible('\uFEFFa'), '⟨U+FEFF⟩a');
  });

  test('경계 안의 모든 범위를 드러낸다', () {
    for (final code in [
      0x200B, 0x200C, 0x200D, 0x200E, 0x200F, //
      0x202A, 0x202B, 0x202C, 0x202D, 0x202E,
      0x2066, 0x2067, 0x2068, 0x2069,
    ]) {
      final hex = code.toRadixString(16).toUpperCase();
      expect(revealInvisible(String.fromCharCode(code)), '⟨U+$hex⟩');
    }
  });

  test('범위 바로 바깥 글자는 그대로 둔다', () {
    for (final code in [0x20, 0x200A, 0x2010, 0x2029, 0x202F, 0x2065, 0x206A]) {
      final s = String.fromCharCode(code);
      expect(revealInvisible(s), s);
    }
  });

  test('보통 한글 · 이모지 · 마크다운은 그대로', () {
    const text = '날짜,가게,금액\n2026-11-02,편의점,4500 👍🏽 # 제목 [a](http://x)';
    expect(revealInvisible(text), text);
  });
}
