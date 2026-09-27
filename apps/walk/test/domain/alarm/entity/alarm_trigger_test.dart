import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';

void main() {
  test('packageId 는 alarmId * 100 + index, alarmIdOf 로 되돌린다', () {
    expect(packageId(12, 34), 1234);
    expect(alarmIdOf(1234), 12);
    expect(alarmIdOf(packageId(9999, 99)), 9999);
  });

  test('triggerIndex 는 날짜로만 정해지고 14일 안에서 겹치지 않는다', () {
    expect(triggerIndex(DateTime(2026, 9, 28, 7)), triggerIndex(DateTime(2026, 9, 28, 23, 59)));
    final indexes = {
      for (var n = 0; n <= 14; n++) triggerIndex(DateTime(2026, 12, 25 + n, 7)),
    };
    expect(indexes, hasLength(15));
    expect(indexes.every((i) => i >= 0 && i < packageIdsPerAlarm), isTrue);
  });
}
