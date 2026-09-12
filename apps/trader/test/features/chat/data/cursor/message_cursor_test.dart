import 'package:daylog/core/error/failure.dart';
import 'package:daylog/features/chat/data/cursor/message_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인코딩한 커서를 되돌리면 같은 값이다', () {
    final cursor = MessageCursor(
      createdAt: DateTime.utc(2026, 8, 28, 10, 30),
      id: 'm1',
    );
    expect(MessageCursor.decode(cursor.encode()), cursor);
  });

  test('첫 페이지를 뜻하는 null 과 빈 문자열은 null 이다', () {
    expect(MessageCursor.decode(null), isNull);
    expect(MessageCursor.decode(''), isNull);
  });

  test('형식이 아닌 값은 Failure 로 막는다', () {
    // 커서는 불투명 문자열이라 바깥에서 만들어 보낼 수 있다. 깨진 값이
    // 그대로 질의로 흘러가지 않게 여기서 걸러야 한다.
    expect(() => MessageCursor.decode('not-a-cursor'), throwsA(isA<Failure>()));
  });

  test('id 가 빠진 커서도 막는다', () {
    expect(
      () => MessageCursor.decode('MjAyNi0wOC0yOFQwMDowMDowMC4wMDBafA=='),
      throwsA(isA<Failure>()),
    );
  });
}
