import 'dart:convert';

import 'package:daylog/core/error/failure.dart';
import 'package:daylog/features/feed/data/cursor/feed_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인코딩한 커서를 그대로 복원한다', () {
    final cursor = FeedCursor(
      createdAt: DateTime.utc(2026, 8, 22, 9, 30, 15, 123, 456),
      id: 'a0ebe833-5c74-41b9-ade0-3d9b53cbada6',
    );

    final restored = FeedCursor.decode(cursor.encode());

    expect(restored, cursor);
    expect(restored!.createdAt.isUtc, isTrue);
  });

  test('로컬 시각도 UTC 로 정규화해 담는다', () {
    final local = DateTime.utc(2026, 8, 22, 9).toLocal();

    final restored = FeedCursor.decode(
      FeedCursor(createdAt: local, id: 'post-id').encode(),
    );

    expect(restored!.createdAt, DateTime.utc(2026, 8, 22, 9));
  });

  test('null 과 빈 문자열은 첫 페이지를 뜻한다', () {
    expect(FeedCursor.decode(null), isNull);
    expect(FeedCursor.decode(''), isNull);
  });

  test('커서 내부 형식은 밖으로 드러나지 않는다', () {
    final encoded = FeedCursor(
      createdAt: DateTime.utc(2026, 8, 22, 9),
      id: 'post-id',
    ).encode();

    expect(encoded, isNot(contains('2026')));
    expect(encoded, isNot(contains('post-id')));
  });

  test('깨진 커서는 validation 실패를 던진다', () {
    expect(
      () => FeedCursor.decode('not-a-cursor!!'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('구분자가 없는 커서도 거부한다', () {
    final broken = base64Url.encode(utf8.encode('2026-08-22T09:00:00.000Z'));

    expect(() => FeedCursor.decode(broken), throwsA(isA<ValidationFailure>()));
  });

  test('id 가 비어 있으면 거부한다', () {
    final broken = base64Url.encode(utf8.encode('2026-08-22T09:00:00.000Z|'));

    expect(() => FeedCursor.decode(broken), throwsA(isA<ValidationFailure>()));
  });
}
