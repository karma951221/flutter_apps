import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/data/alarm/channel_reminder_scheduler.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_reminder.dart';

/// 날짜 기호를 아무도 올리지 않은 상태(헤드리스 엔진 — `MaterialApp` 이 없다). 같은 isolate 의
/// 다른 테스트가 `initializeDateFormatting` 을 부르면 드러나지 않아 파일을 나눈다.
void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));
  final ringAt = DateTime(2026, 10, 9, 7);
  const alarm = Alarm(
    id: 4,
    hour: 7,
    minute: 0,
    repeat: {Weekday.fri},
    label: '출근',
  );

  test('날짜 기호가 없어도 기기 언어 시각 · 날짜로 만든다(대체 문구 07:00 · 10/9 가 아니다)', () async {
    final soon = await ChannelReminderScheduler.prepareArguments(
      AlarmReminder(
        id: reminderId(412, ReminderKind.soon),
        packageId: 412,
        alarmId: 4,
        kind: ReminderKind.soon,
        at: DateTime(2026, 10, 9, 6, 30),
        ringAt: ringAt,
      ),
      alarm,
      ko,
    );
    final holiday = await ChannelReminderScheduler.prepareArguments(
      AlarmReminder(
        id: reminderId(412, ReminderKind.holiday),
        packageId: 412,
        alarmId: 4,
        kind: ReminderKind.holiday,
        at: DateTime(2026, 10, 8, 7),
        ringAt: ringAt,
        holidayName: '한글날',
      ),
      alarm,
      ko,
    );

    expect(soon['body'], '오전 7:00 출근');
    expect(holiday['body'], contains('10월 9일'));
    expect(holiday['body'], contains('오전 7:00'));
  });
}
