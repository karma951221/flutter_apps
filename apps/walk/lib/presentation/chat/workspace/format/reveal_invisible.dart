/// 보이지 않는 글자를 `⟨U+XXXX⟩` 로 드러낸다 — 승인 시트가 모델이 쓰려는 글을 글자 그대로 보일 때.
///
/// 드러내는 것: 제어 문자 U+0000–U+001F(줄바꿈 `\n` · 탭 `\t` 은 그대로) · U+007F ·
/// 폭 없는 글자 U+200B–U+200F · 방향 바꾸는 글자 U+202A–U+202E · U+2066–U+2069 · U+FEFF.
/// 그 밖(한글 · 이모지 등)은 그대로 둔다.
String revealInvisible(String text) {
  // 드러낼 글자가 없으면 새로 만들지 않는다(보통 경우).
  if (!text.runes.any(_isInvisible)) return text;
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (_isInvisible(rune)) {
      out.write('⟨U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}⟩');
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

bool _isInvisible(int rune) =>
    (rune <= 0x1F && rune != 0x0A && rune != 0x09) ||
    rune == 0x7F ||
    (rune >= 0x200B && rune <= 0x200F) ||
    (rune >= 0x202A && rune <= 0x202E) ||
    (rune >= 0x2066 && rune <= 0x2069) ||
    rune == 0xFEFF;
