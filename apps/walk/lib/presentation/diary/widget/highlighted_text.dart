import 'package:flutter/material.dart';

/// [text] 에서 [query] 와 겹치지 않게 앞에서부터 일치하는 구간들(`[start, end)`, UTF-16 위치).
/// 영문은 대소문자를 가리지 않는다(검색 쿼리의 SQLite `LIKE` 와 같은 규칙 — ASCII 만).
/// [query] 가 비면 일치 없음.
List<(int, int)> matchRanges(String text, String query) {
  if (query.isEmpty) return const [];
  final haystack = _asciiLower(text);
  final needle = _asciiLower(query);
  final ranges = <(int, int)>[];
  var from = 0;
  while (true) {
    final i = haystack.indexOf(needle, from);
    if (i < 0) return ranges;
    ranges.add((i, i + needle.length));
    from = i + needle.length;
  }
}

/// 목록 한 줄용 본문 조각. 줄바꿈 · 연속 공백을 공백 하나로 접고, 첫 일치가 [lead] 글자보다
/// 뒤에 있으면 그 조금 앞에서 잘라 `…` 를 붙인다 — 긴 본문에서도 일치 부분이 보이게.
/// 자르는 자리가 이모지(서로게이트 쌍) 가운데면 그 글자를 통째로 넣는다.
String matchSnippet(String text, String query, {int lead = 24}) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final ranges = matchRanges(flat, query);
  if (ranges.isEmpty || ranges.first.$1 <= lead) return flat;
  var start = ranges.first.$1 - lead;
  if (_isLowSurrogate(flat.codeUnitAt(start))) start--;
  return '…${flat.substring(start)}';
}

/// 일치한 부분을 굵게 그리는 글(검색 결과 강조, 스펙 §6.4).
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    required this.query,
    this.style,
    this.maxLines,
    super.key,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final strong = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in matchRanges(text, query)) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      spans.add(TextSpan(text: text.substring(start, end), style: strong));
      at = end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// A–Z 만 소문자로 — 길이(UTF-16 위치)가 그대로라 원문 위치에 바로 쓸 수 있다.
String _asciiLower(String s) => String.fromCharCodes([
  for (final c in s.codeUnits) c >= 0x41 && c <= 0x5A ? c + 0x20 : c,
]);

bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
