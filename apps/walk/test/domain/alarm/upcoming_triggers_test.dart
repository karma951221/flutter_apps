import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/upcoming_triggers.dart';

const _weekdays = {Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri};
const _everyDay = {...Weekday.values};

void main() {
  // 2026-09-28 은 월요일.
  final mondayNoon = DateTime(2026, 9, 28, 12);

  group('upcomingTriggers', () {
    test('꺼진 알람은 빈 목록', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay, enabled: false);
      expect(upcomingTriggers(alarm, mondayNoon), isEmpty);
    });

    test('반복 요일만, 오름차순, 14일 안', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 30, repeat: {Weekday.mon, Weekday.thu});
      expect(upcomingTriggers(alarm, mondayNoon), [
        DateTime(2026, 10, 1, 7, 30), // 목
        DateTime(2026, 10, 5, 7, 30), // 월
        DateTime(2026, 10, 8, 7, 30), // 목
        DateTime(2026, 10, 12, 7, 30), // 월
      ]);
    });

    test('오늘 시각이 이미 지났으면 오늘은 빠진다', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay);
      final triggers = upcomingTriggers(alarm, mondayNoon);
      expect(triggers.first, DateTime(2026, 9, 29, 7));
      expect(triggers, hasLength(14));
    });

    test('오늘 시각이 아직이면 오늘이 첫 회차', () {
      const alarm = Alarm(id: 1, hour: 18, minute: 0, repeat: _weekdays);
      expect(upcomingTriggers(alarm, mondayNoon).first, DateTime(2026, 9, 28, 18));
    });

    test('now 와 같은 시각은 포함하지 않는다', () {
      const alarm = Alarm(id: 1, hour: 12, minute: 0, repeat: _everyDay);
      expect(upcomingTriggers(alarm, mondayNoon).first, DateTime(2026, 9, 29, 12));
    });

    test('자정 직전 · 직후', () {
      const midnight = Alarm(id: 1, hour: 0, minute: 0, repeat: {Weekday.tue});
      // 월 23:59 → 화 00:00 이 1분 뒤
      expect(
        upcomingTriggers(midnight, DateTime(2026, 9, 28, 23, 59)).first,
        DateTime(2026, 9, 29),
      );
      // 화 00:01 → 다음 주 화요일
      expect(
        upcomingTriggers(midnight, DateTime(2026, 9, 29, 0, 1)).first,
        DateTime(2026, 10, 6),
      );
    });

    test('14일 경계: now + 14일과 같은 시각은 포함, 넘으면 제외', () {
      const alarm = Alarm(id: 1, hour: 12, minute: 0, repeat: {Weekday.mon});
      expect(upcomingTriggers(alarm, mondayNoon).last, DateTime(2026, 10, 12, 12));
      const later = Alarm(id: 1, hour: 12, minute: 1, repeat: {Weekday.mon});
      expect(upcomingTriggers(later, mondayNoon), [
        DateTime(2026, 9, 28, 12, 1),
        DateTime(2026, 10, 5, 12, 1),
      ]);
    });

    test('월말을 넘어가도 날짜가 맞다', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 0, repeat: _everyDay);
      final triggers = upcomingTriggers(alarm, DateTime(2026, 1, 30, 8));
      expect(triggers.take(3), [
        DateTime(2026, 1, 31, 7),
        DateTime(2026, 2, 1, 7),
        DateTime(2026, 2, 2, 7),
      ]);
    });

    test('1회성: oneShotAt 이 뒤면 그 시각, 지났으면 빈 목록', () {
      final alarm = Alarm(id: 1, hour: 7, minute: 0, oneShotAt: DateTime(2026, 9, 29, 7));
      expect(upcomingTriggers(alarm, mondayNoon), [DateTime(2026, 9, 29, 7)]);
      expect(upcomingTriggers(alarm, DateTime(2026, 9, 29, 7)), isEmpty);
    });

    test('1회성인데 oneShotAt 이 없으면 빈 목록', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 0);
      expect(upcomingTriggers(alarm, mondayNoon), isEmpty);
    });
  });

  group('nextOccurrence', () {
    test('오늘 시각이 뒤면 오늘, 아니면 내일', () {
      expect(nextOccurrence(13, 0, mondayNoon), DateTime(2026, 9, 28, 13));
      expect(nextOccurrence(12, 0, mondayNoon), DateTime(2026, 9, 29, 12));
      expect(nextOccurrence(7, 0, DateTime(2026, 9, 30, 8)), DateTime(2026, 10, 1, 7));
    });
  });

  group('triggersOf', () {
    test('triggersOf 는 날짜 index 로 packageId 를 준다', () {
      const alarm = Alarm(id: 7, hour: 7, minute: 0, repeat: {Weekday.tue});
      final first = triggersOf(alarm, mondayNoon).first;
      expect(first.at, DateTime(2026, 9, 29, 7));
      expect(first.alarmId, 7);
      expect(first.packageId, packageId(7, triggerIndex(DateTime(2026, 9, 29))));
    });
  });
}
