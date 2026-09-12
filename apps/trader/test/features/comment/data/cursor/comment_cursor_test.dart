import 'package:core/core.dart';
import 'package:daylog/features/comment/data/cursor/comment_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인코딩한 커서를 그대로 되돌린다', () {
    final cursor = CommentCursor(
      createdAt: DateTime.utc(2026, 8, 23, 9, 30),
      id: 'comment-1',
    );

    final decoded = CommentCursor.decode(cursor.encode());

    expect(decoded, cursor);
  });

  test('null 과 빈 문자열은 첫 페이지를 뜻한다', () {
    expect(CommentCursor.decode(null), isNull);
    expect(CommentCursor.decode(''), isNull);
  });

  test('형식이 아니면 validation 실패를 던진다', () {
    expect(
      () => CommentCursor.decode('not-a-cursor'),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
