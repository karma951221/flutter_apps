import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer_segments.freezed.dart';

/// 답 글의 한 조각 — 마크다운으로 그릴 글, 또는 그림으로 그릴 SVG 코드 블록.
@freezed
sealed class AnswerSegment with _$AnswerSegment {
  const factory AnswerSegment.markdown(String text) = MarkdownSegment;

  /// [svg] 는 블록 안 SVG 코드(trim), [source] 는 울타리까지 포함한 원문 —
  /// 그림을 그리지 못하면 [source] 를 코드 블록으로 보인다.
  const factory AnswerSegment.svg({
    required String svg,
    required String source,
  }) = SvgSegment;
}

/// 답 글을 마크다운 조각과 SVG 조각으로 나눈다. 순수 함수.
///
/// SVG 조각은 **닫힌** 코드 울타리(``` · ~~~) 중 정보 문자열이 `svg` 이거나, 비었거나
/// `xml` · `html` 이면서 내용이 `<svg` 로 시작하는 것 — 내용이 `<svg … </svg>` 꼴이고
/// [maxSvgChars] 이하일 때만. 닫히지 않은 울타리(흐르는 중)는 마크다운 그대로다.
/// 다른 코드 블록은 손대지 않는다.
abstract final class AnswerSegments {
  /// 그림으로 그릴 SVG 의 최대 글자 수. 넘으면 코드 블록으로 둔다.
  static const maxSvgChars = 200000;

  static final _open = RegExp(r'^ {0,3}(`{3,}|~{3,})\s*([^\s`]*)[^`]*$');

  static List<AnswerSegment> parse(String text) {
    final lines = text.split('\n');
    final segments = <AnswerSegment>[];
    final pending = <String>[];

    void flush() {
      if (pending.isEmpty) return;
      final chunk = pending.join('\n');
      pending.clear();
      if (chunk.trim().isNotEmpty) segments.add(AnswerSegment.markdown(chunk));
    }

    var i = 0;
    while (i < lines.length) {
      final open = _open.firstMatch(lines[i]);
      if (open == null) {
        pending.add(lines[i]);
        i++;
        continue;
      }
      final fence = open.group(1)!;
      final info = open.group(2)!.toLowerCase();
      final close = _closeIndex(lines, i + 1, fence);
      if (close == null) {
        // 닫히지 않았다 — 끝까지 마크다운(코드 블록)으로.
        pending.addAll(lines.sublist(i));
        break;
      }
      final body = lines.sublist(i + 1, close).join('\n').trim();
      final block = lines.sublist(i, close + 1);
      if (_isSvg(info, body)) {
        flush();
        segments.add(AnswerSegment.svg(svg: body, source: block.join('\n')));
      } else {
        pending.addAll(block);
      }
      i = close + 1;
    }
    flush();
    return segments;
  }

  /// [from] 부터 [fence] 와 같은 글자로 같거나 긴 닫는 줄. 없으면 null.
  static int? _closeIndex(List<String> lines, int from, String fence) {
    final char = fence[0] == '`' ? '`' : '~';
    final close = RegExp(
      '^ {0,3}${RegExp.escape(char)}{${fence.length},}\\s*\$',
    );
    for (var j = from; j < lines.length; j++) {
      if (close.hasMatch(lines[j])) return j;
    }
    return null;
  }

  static bool _isSvg(String info, String body) {
    final tagged =
        info == 'svg' ||
        ((info.isEmpty || info == 'xml' || info == 'html') &&
            body.startsWith('<svg'));
    if (!tagged) return false;
    if (body.length > maxSvgChars) return false;
    final start = body.indexOf('<svg');
    return start >= 0 && start < 200 && body.endsWith('</svg>');
  }
}
