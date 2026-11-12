import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/attachment/answer_file.dart';

void main() {
  final at = DateTime(2026, 11, 13, 14, 5);

  group('fileName', () {
    test('날짜 · 시각 · 질문 슬러그', () {
      expect(
        AnswerFile.fileName(at, '이번 달 영수증 정리해 줘'),
        '20261113-1405-이번-달-영수증-정리해-줘.md',
      );
    });

    test('빈 질문은 답', () {
      expect(AnswerFile.fileName(at, '  '), endsWith('-답.md'));
    });

    test('파일 이름에 못 쓰는 글자는 뺀다', () {
      final name = AnswerFile.fileName(at, 'a/b:c');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, '20261113-1405-abc.md');
    });

    test('첫 줄의 앞 20자만 쓴다', () {
      expect(
        AnswerFile.fileName(at, '${'가' * 30}\n둘째 줄'),
        '20261113-1405-${'가' * 20}.md',
      );
    });

    test('금지 글자뿐이면 답', () {
      expect(AnswerFile.fileName(at, '///'), '20261113-1405-답.md');
    });
  });

  group('markdown', () {
    test('첨부 있음', () {
      expect(
        AnswerFile.markdown(
          question: '영수증 정리해 줘\n둘째 줄',
          answer: '정리했어요.',
          model: 'claude-x',
          at: at,
          attachmentNames: ['a.pdf', 'b.jpg'],
        ),
        '# 영수증 정리해 줘\n'
        '\n'
        '- 날짜: 2026-11-13 14:05\n'
        '- 모델: claude-x\n'
        '- 첨부: a.pdf, b.jpg\n'
        '\n'
        '---\n'
        '\n'
        '정리했어요.\n',
      );
    });

    test('첨부 없으면 첨부 줄이 없다', () {
      expect(
        AnswerFile.markdown(
          question: '안녕',
          answer: '네',
          model: 'gpt-y',
          at: at,
          attachmentNames: const [],
        ),
        '# 안녕\n'
        '\n'
        '- 날짜: 2026-11-13 14:05\n'
        '- 모델: gpt-y\n'
        '\n'
        '---\n'
        '\n'
        '네\n',
      );
    });
  });
}
