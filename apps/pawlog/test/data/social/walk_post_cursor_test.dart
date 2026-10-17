import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/social/walk_post_cursor.dart';

void main() {
  test('encode/decode 왕복 — 마이크로초까지 보존하고 UTC 로 둔다', () {
    final cursor = WalkPostCursor(
      createdAt: DateTime.utc(2026, 10, 17, 9, 0, 0, 123, 456),
      id: 'b6f0c3a2-0000-4000-8000-000000000001',
    );

    final decoded = WalkPostCursor.decode(cursor.encode())!;

    expect(decoded, cursor);
    expect(decoded.createdAt.isUtc, isTrue);
  });

  test('현지 시각으로 만들어도 같은 순간이다', () {
    final local = DateTime(2026, 10, 17, 18);
    final cursor = WalkPostCursor(createdAt: local, id: 'p1');

    expect(WalkPostCursor.decode(cursor.encode())!.createdAt, local.toUtc());
  });

  test('null · 빈 문자열은 null', () {
    expect(WalkPostCursor.decode(null), isNull);
    expect(WalkPostCursor.decode(''), isNull);
  });

  test('깨진 커서는 feedCursorInvalid', () {
    expect(
      () => WalkPostCursor.decode('not-a-cursor'),
      throwsA(
        isA<Failure>().having(
          (f) => f.failureCode,
          'failureCode',
          FailureCode.feedCursorInvalid,
        ),
      ),
    );
  });
}
