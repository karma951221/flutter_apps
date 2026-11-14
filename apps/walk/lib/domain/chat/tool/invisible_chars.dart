/// 화면에 보이지 않거나 글 방향을 바꾸는 글자인지. 승인 시트는 이 글자를 `⟨U+XXXX⟩` 로 드러내고,
/// 쓰기 도구는 이런 글자가 든 파일 이름을 받지 않는다(`out/a⟨U+202E⟩dm.txt` 가 `out/atxt.md` 로 보이지 않게).
///
/// 제어 문자 U+0000–U+001F(줄바꿈 `\n` · 탭 `\t` 제외) · U+007F · 폭 없는 글자 U+200B–U+200F ·
/// 방향 바꾸는 글자 U+202A–U+202E · U+2066–U+2069 · U+FEFF.
bool isInvisibleRune(int rune) =>
    (rune <= 0x1F && rune != 0x0A && rune != 0x09) ||
    rune == 0x7F ||
    (rune >= 0x200B && rune <= 0x200F) ||
    (rune >= 0x202A && rune <= 0x202E) ||
    (rune >= 0x2066 && rune <= 0x2069) ||
    rune == 0xFEFF;
