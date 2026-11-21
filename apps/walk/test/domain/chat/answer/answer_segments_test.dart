import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/answer/answer_segments.dart';

const _svg = '<svg viewBox="0 0 10 10"><rect width="10" height="10"/></svg>';

void main() {
  group('AnswerSegments.parse', () {
    test('svg 블록이 없으면 글 전체가 마크다운 한 조각', () {
      const text = '# 제목\n\n- 하나\n- 둘\n\n```dart\nprint(1);\n```';
      expect(AnswerSegments.parse(text), [const AnswerSegment.markdown(text)]);
    });

    test('닫힌 ```svg 블록은 앞뒤 글과 나뉜 svg 조각', () {
      const text = '앞 글\n```svg\n$_svg\n```\n뒷 글';
      expect(AnswerSegments.parse(text), [
        const AnswerSegment.markdown('앞 글'),
        const AnswerSegment.svg(svg: _svg, source: '```svg\n$_svg\n```'),
        const AnswerSegment.markdown('뒷 글'),
      ]);
    });

    test('~~~ 울타리 · 대문자 정보 · 긴 닫는 울타리도 된다', () {
      const text = '~~~SVG\n$_svg\n~~~~';
      expect(AnswerSegments.parse(text).single, isA<SvgSegment>());
    });

    test('정보가 없거나 xml 이어도 내용이 <svg 로 시작하면 svg', () {
      expect(AnswerSegments.parse('```\n$_svg\n```').single, isA<SvgSegment>());
      expect(
        AnswerSegments.parse('```xml\n$_svg\n```').single,
        isA<SvgSegment>(),
      );
      expect(
        AnswerSegments.parse('```xml\n<a/>\n```').single,
        isA<MarkdownSegment>(),
      );
    });

    test('닫히지 않은 svg 블록(흐르는 중)은 마크다운 그대로', () {
      const text = '그림:\n```svg\n<svg viewBox="0 0 1 1">';
      expect(AnswerSegments.parse(text), [const AnswerSegment.markdown(text)]);
    });

    test('</svg> 로 끝나지 않는 svg 블록은 코드 블록으로 둔다', () {
      const text = '```svg\n<svg><rect/>\n```';
      expect(AnswerSegments.parse(text), [const AnswerSegment.markdown(text)]);
    });

    test('다른 코드 블록 안의 ```svg 글자는 svg 로 보지 않는다', () {
      const text = '````md\n```svg\n$_svg\n```\n````';
      expect(AnswerSegments.parse(text), [const AnswerSegment.markdown(text)]);
    });

    test('너무 긴 svg 는 코드 블록으로 둔다', () {
      final big = '<svg>${'a' * AnswerSegments.maxSvgChars}</svg>';
      expect(
        AnswerSegments.parse('```svg\n$big\n```').single,
        isA<MarkdownSegment>(),
      );
    });

    test('빈 글 조각은 버린다', () {
      const text = '\n```svg\n$_svg\n```\n\n';
      expect(AnswerSegments.parse(text).single, isA<SvgSegment>());
      expect(AnswerSegments.parse(''), isEmpty);
    });
  });
}
