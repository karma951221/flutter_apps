import '../../../../domain/chat/tool/invisible_chars.dart';

/// 보이지 않는 글자를 `⟨U+XXXX⟩` 로 드러낸다 — 승인 시트가 모델이 쓰려는 글을 글자 그대로 보일 때.
///
/// 드러내는 글자는 [isInvisibleRune](줄바꿈 · 탭은 그대로). 그 밖(한글 · 이모지 등)은 그대로 둔다.
String revealInvisible(String text) {
  // 드러낼 글자가 없으면 새로 만들지 않는다(보통 경우).
  if (!text.runes.any(isInvisibleRune)) return text;
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (isInvisibleRune(rune)) {
      out.write('⟨U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}⟩');
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}
