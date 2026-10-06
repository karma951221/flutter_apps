import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/repeat_preset.dart';

void main() {
  test('묶음의 요일', () {
    expect(RepeatPreset.everyday.days, Weekday.values.toSet());
    expect(RepeatPreset.weekdays.days, {
      Weekday.mon,
      Weekday.tue,
      Weekday.wed,
      Weekday.thu,
      Weekday.fri,
    });
    expect(RepeatPreset.weekend.days, {Weekday.sat, Weekday.sun});
  });

  group('of', () {
    test('요일 집합이 묶음과 같으면 그 묶음(순서 상관없음)', () {
      expect(RepeatPreset.of(Weekday.values.reversed.toSet()), RepeatPreset.everyday);
      expect(
        RepeatPreset.of(const {Weekday.fri, Weekday.thu, Weekday.wed, Weekday.tue, Weekday.mon}),
        RepeatPreset.weekdays,
      );
      expect(RepeatPreset.of(const {Weekday.sun, Weekday.sat}), RepeatPreset.weekend);
    });

    test('그 밖(빈 집합 · 일부 · 넘침)은 null', () {
      expect(RepeatPreset.of(const {}), isNull);
      expect(RepeatPreset.of(const {Weekday.sat}), isNull);
      expect(RepeatPreset.of(const {Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu}), isNull);
      expect(
        RepeatPreset.of(const {
          Weekday.mon,
          Weekday.tue,
          Weekday.wed,
          Weekday.thu,
          Weekday.fri,
          Weekday.sat,
        }),
        isNull,
      );
    });
  });
}
