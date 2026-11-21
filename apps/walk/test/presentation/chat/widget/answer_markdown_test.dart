import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/answer/answer_segments.dart';
import 'package:walk/presentation/chat/widget/answer_markdown.dart';

void main() {
  group('withCursor', () {
    test('마지막 글 조각 끝에 붙인다', () {
      expect(AnswerMarkdown.withCursor([const AnswerSegment.markdown('안녕')]), [
        const AnswerSegment.markdown('안녕▍'),
      ]);
    });

    test('표 줄 끝이면 새 문단으로 — 표가 깨지지 않게', () {
      const table = '| a | b |\n|---|---|\n| 1 | 2 |';
      expect(AnswerMarkdown.withCursor([const AnswerSegment.markdown(table)]), [
        const AnswerSegment.markdown('$table\n\n▍'),
      ]);
    });

    test('마지막이 그림이거나 비었으면 커서 조각을 덧붙인다', () {
      const svg = AnswerSegment.svg(svg: '<svg></svg>', source: 's');
      expect(AnswerMarkdown.withCursor([svg]), [
        svg,
        const AnswerSegment.markdown('▍'),
      ]);
      expect(AnswerMarkdown.withCursor([]), [const AnswerSegment.markdown('▍')]);
    });
  });

  group('workspacePathOf', () {
    test('out/ · inbox/ 상대 경로만, 퍼센트 인코딩은 푼다', () {
      expect(
        AnswerMarkdown.workspacePathOf(Uri.parse('out/%EA%B7%B8%EB%A6%BC.png')),
        'out/그림.png',
      );
      expect(
        AnswerMarkdown.workspacePathOf(Uri.parse('inbox/a.jpg')),
        'inbox/a.jpg',
      );
    });

    test('웹 주소 · 다른 폴더 · .. 는 null', () {
      expect(
        AnswerMarkdown.workspacePathOf(Uri.parse('https://x.com/out/a.png')),
        isNull,
      );
      expect(AnswerMarkdown.workspacePathOf(Uri.parse('/out/a.png')), isNull);
      expect(AnswerMarkdown.workspacePathOf(Uri.parse('etc/a.png')), isNull);
      expect(
        AnswerMarkdown.workspacePathOf(Uri.parse('out/../secret.png')),
        isNull,
      );
    });
  });
}
