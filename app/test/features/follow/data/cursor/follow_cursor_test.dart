import 'package:daylog/core/error/failure.dart';
import 'package:daylog/features/follow/data/cursor/follow_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인코딩한 커서를 그대로 되돌린다', () {
    final cursor = FollowCursor(
      createdAt: DateTime.utc(2026, 8, 30, 9),
      id: 'user-1',
    );

    expect(FollowCursor.decode(cursor.encode()), cursor);
  });

  test('첫 페이지를 뜻하는 null 과 빈 문자열은 null 이다', () {
    expect(FollowCursor.decode(null), isNull);
    expect(FollowCursor.decode(''), isNull);
  });

  test('시각은 UTC 로 실어 보낸다', () {
    final local = DateTime.utc(2026, 8, 30, 9).toLocal();

    final decoded = FollowCursor.decode(
      FollowCursor(createdAt: local, id: 'user-1').encode(),
    );

    expect(decoded!.createdAt, DateTime.utc(2026, 8, 30, 9));
  });

  test('깨진 커서는 ValidationFailure 를 던진다', () {
    expect(
      () => FollowCursor.decode('not-a-cursor'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('구분자가 없는 커서도 거부한다', () {
    expect(
      () => FollowCursor.decode('MjAyNi0wOC0zMA=='),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
