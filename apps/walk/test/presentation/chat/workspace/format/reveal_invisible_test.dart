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

  test('넓힌 글자도 드러낸다 — 4자리 넘는 코드 포인트는 글자 하나로', () {
    expect(revealInvisible('a\u{E0041}b'), 'a⟨U+E0041⟩b');
    expect(revealInvisible('\u2060'), '⟨U+2060⟩');
    expect(revealInvisible('\u00AD'), '⟨U+00AD⟩');
    expect(revealInvisible('\u3164'), '⟨U+3164⟩');
    for (final code in [
      0x00AD, 0x061C, 0x115F, 0x1160, 0x180E, //
      0x2060, 0x2061, 0x2062, 0x2063, 0x2064, 0x3164,
      0xFFF9, 0xFFFA, 0xFFFB,
      0xE0000, 0xE0001, 0xE007F, 0xE0100, 0xE01EF,
    ]) {
      final hex = code.toRadixString(16).toUpperCase().padLeft(4, '0');
      expect(revealInvisible(String.fromCharCode(code)), '⟨U+$hex⟩');
    }
  });

  test('이모지 변형 선택자 U+FE0E · U+FE0F 는 그대로', () {
    for (final s in ['\u2764\uFE0F', '\u2764\uFE0E']) {
      expect(revealInvisible(s), s);
    }
  });

  test('범위 바로 바깥 글자는 그대로 둔다', () {
    for (final code in [
      0x20, 0x200A, 0x2010, 0x2029, 0x202F, 0x2065, 0x206A, //
      0x00AC,
      0x00AE,
      0x2059,
      0xFFF8,
      0xFFFC,
      0xDFFFF,
      0xE0080,
      0xE00FF,
      0xE01F0,
    ]) {
      final s = String.fromCharCode(code);
      expect(revealInvisible(s), s);
    }
  });

  test('보통 한글 · 이모지 · 마크다운은 그대로', () {
    const text = '날짜,가게,금액\n2026-11-02,편의점,4500 👍🏽 # 제목 [a](http://x)';
    expect(revealInvisible(text), text);
  });
}
