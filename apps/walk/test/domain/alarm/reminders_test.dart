import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_reminder.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/reminders.dart';

class _Holidays implements HolidayCalendar {
  _Holidays(this.days);

  final Map<DateTime, String> days;

  @override
  String? nameOf(DateTime date) =>
      days[DateTime(date.year, date.month, date.day)];

  @override
  HolidaySource get source =>
      const HolidaySource.bundled(firstYear: 2026, lastYear: 2027);
}

const _everyDay = {...Weekday.values};

void main() {
  // 2026-10-07 수요일 정오. 10월 9일(금)은 한글날.
  final now = DateTime(2026, 10, 7, 12);
  final hangul = DateTime(2026, 10, 9);
  final holidays = _Holidays({hangul: '한글날'});
  final none = _Holidays({});

  AlarmTrigger trigger(int alarmId, DateTime at) => AlarmTrigger(
    packageId: packageId(alarmId, triggerIndex(at)),
    alarmId: alarmId,
    at: at,
  );

  List<AlarmReminder> remind(
    Alarm alarm,
    List<DateTime> ringAts, {
    HolidayCalendar? calendar,
    bool holidayReminder = true,
  }) => remindersOf(
    alarm,
    [for (final at in ringAts) trigger(alarm.id, at)],
    now,
    holidays: calendar ?? none,
    holidayReminder: holidayReminder,
  );

  group('리드 시간', () {
    test('기본은 30분 · 24시간', () {
      expect(alarmSoonLead, const Duration(minutes: 30));
      expect(alarmHolidayLead, const Duration(hours: 24));
    });
  });

  group('reminderId', () {
    test('1_000_000 + packageId * 2 + 종류', () {
      expect(reminderId(123, ReminderKind.soon), 1000246);
      expect(reminderId(123, ReminderKind.holiday), 1000247);
    });

    test('패키지 id · 포크 자리표시 알림(973422)과 겹치지 않는다', () {
      final smallest = reminderId(packageId(1, 0), ReminderKind.soon);
      final largest = reminderId(
        packageId(Alarm.maxId, packageIdsPerAlarm - 1),
        ReminderKind.holiday,
      );
      expect(
        smallest,
        greaterThan(packageId(Alarm.maxId, packageIdsPerAlarm - 1)),
      );
      expect(smallest, greaterThan(973422));
      // 안드로이드 요청 코드 · 알림 id 는 int32.
      expect(largest, lessThan(1 << 31));
    });
  });

  group('soon', () {
    final ring = DateTime(2026, 10, 8, 7);

    test('remindBefore 가 꺼져 있으면 없다', () {
      expect(
        remind(const Alarm(id: 3, hour: 7, minute: 0, repeat: _everyDay), [
          ring,
        ]),
        isEmpty,
      );
    });

    test('켜져 있으면 회차마다 30분 전', () {
      const alarm = Alarm(
        id: 3,
        hour: 7,
        minute: 0,
        repeat: _everyDay,
        remindBefore: true,
      );
      final next = DateTime(2026, 10, 10, 7);

      expect(remind(alarm, [ring, next]), [
        AlarmReminder(
          id: reminderId(packageId(3, triggerIndex(ring)), ReminderKind.soon),
          packageId: packageId(3, triggerIndex(ring)),
          alarmId: 3,
          kind: ReminderKind.soon,
          at: DateTime(2026, 10, 8, 6, 30),
          ringAt: ring,
        ),
        AlarmReminder(
          id: reminderId(packageId(3, triggerIndex(next)), ReminderKind.soon),
          packageId: packageId(3, triggerIndex(next)),
          alarmId: 3,
          kind: ReminderKind.soon,
          at: DateTime(2026, 10, 10, 6, 30),
          ringAt: next,
        ),
      ]);
    });

    test('1회성도 받는다', () {
      final alarm = Alarm(
        id: 3,
        hour: 7,
        minute: 0,
        remindBefore: true,
        oneShotAt: ring,
      );
      expect(remind(alarm, [ring]).single.kind, ReminderKind.soon);
    });

    test('울릴 시각이 30분 이내면 만들지 않는다(경계 포함)', () {
      const alarm = Alarm(
        id: 3,
        hour: 12,
        minute: 30,
        repeat: _everyDay,
        remindBefore: true,
      );
      expect(remind(alarm, [DateTime(2026, 10, 7, 12, 30)]), isEmpty);
      expect(remind(alarm, [DateTime(2026, 10, 7, 12, 10)]), isEmpty);
      expect(
        remind(alarm, [DateTime(2026, 10, 7, 12, 30, 1)]).single.at,
        DateTime(2026, 10, 7, 12, 0, 1),
      );
    });

    test('리드 시간을 바꿀 수 있다', () {
      const alarm = Alarm(
        id: 3,
        hour: 7,
        minute: 0,
        repeat: _everyDay,
        remindBefore: true,
      );
      final reminders = remindersOf(
        alarm,
        [trigger(3, ring)],
        now,
        holidays: none,
        holidayReminder: true,
        soonLead: const Duration(minutes: 2),
      );
      expect(reminders.single.at, DateTime(2026, 10, 8, 6, 58));
    });
  });

  group('holiday', () {
    const alarm = Alarm(id: 4, hour: 7, minute: 0, repeat: _everyDay);
    final holidayRing = DateTime(2026, 10, 9, 7);

    test('반복 알람의 공휴일 회차는 24시간 전에 이름과 함께', () {
      expect(
        remind(alarm, [
          DateTime(2026, 10, 8, 7),
          holidayRing,
        ], calendar: holidays),
        [
          AlarmReminder(
            id: reminderId(
              packageId(4, triggerIndex(holidayRing)),
              ReminderKind.holiday,
            ),
            packageId: packageId(4, triggerIndex(holidayRing)),
            alarmId: 4,
            kind: ReminderKind.holiday,
            at: DateTime(2026, 10, 8, 7),
            ringAt: holidayRing,
            holidayName: '한글날',
          ),
        ],
      );
    });

    test('24시간 전이 이미 지났으면 지금 띄운다', () {
      final soonHoliday = _Holidays({DateTime(2026, 10, 8): '임시공휴일'});
      final reminder = remind(alarm, [
        DateTime(2026, 10, 8, 7),
      ], calendar: soonHoliday).single;
      expect(reminder.at, now);
      expect(reminder.ringAt, DateTime(2026, 10, 8, 7));
    });

    test('1회성은 공휴일 미리 알림이 없다', () {
      final oneShot = Alarm(id: 4, hour: 7, minute: 0, oneShotAt: holidayRing);
      expect(remind(oneShot, [holidayRing], calendar: holidays), isEmpty);
    });

    test('설정을 끄면 없다', () {
      expect(
        remind(
          alarm,
          [holidayRing],
          calendar: holidays,
          holidayReminder: false,
        ),
        isEmpty,
      );
    });

    test('지난 회차는 없다', () {
      final past = _Holidays({DateTime(2026, 10, 7): '가짜'});
      expect(
        remind(alarm, [DateTime(2026, 10, 7, 7)], calendar: past),
        isEmpty,
      );
    });

    test('soon 과 함께 켜지면 둘 다', () {
      final both = remind(alarm.copyWith(remindBefore: true), [
        holidayRing,
      ], calendar: holidays);
      expect(both.map((r) => r.kind), unorderedEquals(ReminderKind.values));
      expect(both.map((r) => r.id).toSet(), hasLength(2));
    });
  });
}
