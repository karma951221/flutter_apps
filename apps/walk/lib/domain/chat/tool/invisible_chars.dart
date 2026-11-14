/// 화면에 보이지 않거나 글 방향을 바꾸는 글자인지. 승인 시트는 이 글자를 `⟨U+XXXX⟩` 로 드러내고,
/// 쓰기 도구는 이런 글자가 든 파일 이름을 받지 않는다(`out/a⟨U+202E⟩dm.txt` 가 `out/atxt.md` 로 보이지 않게).
///
/// 제어 문자 U+0000–U+001F(줄바꿈 `\n` · 탭 `\t` 제외) · U+007F · 보이지 않는 하이픈 U+00AD ·
/// 아랍 글자 표시 U+061C · 한글 채움 글자 U+115F · U+1160 · U+3164 · 몽골 모음 구분 U+180E ·
/// 폭 없는 글자 U+200B–U+200F · 방향 바꾸는 글자 U+202A–U+202E · U+2066–U+2069 ·
/// 단어 잇기 · 보이지 않는 연산자 U+2060–U+2064 · U+FEFF · 주석 표시 U+FFF9–U+FFFB ·
/// 태그 글자 U+E0000–U+E007F · 변형 선택자 U+E0100–U+E01EF.
/// 이모지 변형 선택자 U+FE0E · U+FE0F 는 보통 글에 흔해 넣지 않는다.
bool isInvisibleRune(int rune) =>
    (rune <= 0x1F && rune != 0x0A && rune != 0x09) ||
    rune == 0x7F ||
    rune == 0xAD ||
    rune == 0x061C ||
    rune == 0x115F ||
    rune == 0x1160 ||
    rune == 0x180E ||
    (rune >= 0x200B && rune <= 0x200F) ||
    (rune >= 0x202A && rune <= 0x202E) ||
    (rune >= 0x2060 && rune <= 0x2064) ||
    (rune >= 0x2066 && rune <= 0x2069) ||
    rune == 0x3164 ||
    rune == 0xFEFF ||
    (rune >= 0xFFF9 && rune <= 0xFFFB) ||
    (rune >= 0xE0000 && rune <= 0xE007F) ||
    (rune >= 0xE0100 && rune <= 0xE01EF);
