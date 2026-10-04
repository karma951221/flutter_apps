import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  test('기본 시계는 지금 시각을 준다', () {
    final before = DateTime.now();
    final now = const Clock().now();
    final after = DateTime.now();

    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });

  test('상속해 now 를 고정할 수 있다', () {
    final fixed = DateTime(2026, 10, 4, 9);

    expect(_FixedClock(fixed).now(), fixed);
  });
}
