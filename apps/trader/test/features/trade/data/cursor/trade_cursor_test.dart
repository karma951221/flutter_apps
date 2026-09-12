import 'package:core/core.dart';
import 'package:daylog/features/trade/data/cursor/trade_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인코딩한 커서를 그대로 되돌린다', () {
    final cursor = TradeCursor(
      createdAt: DateTime.utc(2026, 8, 30, 9),
      id: 'session-1',
    );

    expect(TradeCursor.decode(cursor.encode()), cursor);
  });

  test('첫 페이지를 뜻하는 null 과 빈 문자열은 null 이다', () {
    expect(TradeCursor.decode(null), isNull);
    expect(TradeCursor.decode(''), isNull);
  });

  test('시각은 UTC 로 실어 보낸다', () {
    final local = DateTime.utc(2026, 8, 30, 9).toLocal();

    final decoded = TradeCursor.decode(
      TradeCursor(createdAt: local, id: 'session-1').encode(),
    );

    expect(decoded!.createdAt, DateTime.utc(2026, 8, 30, 9));
  });

  test('깨진 커서는 ValidationFailure 를 던진다', () {
    expect(
      () => TradeCursor.decode('not-a-cursor'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('구분자가 없는 커서도 거부한다', () {
    expect(
      () => TradeCursor.decode('MjAyNi0wOC0zMA=='),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
