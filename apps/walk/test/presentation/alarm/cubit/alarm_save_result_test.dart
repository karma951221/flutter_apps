import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';
import 'package:walk/presentation/alarm/cubit/alarm_save_result.dart';

void main() {
  final now = DateTime(2026, 9, 27, 23, 48); // 일요일
  final oneShot = Alarm(hour: 23, minute: 58, oneShotAt: DateTime(2026, 9, 27, 23, 58));
  const monday = Alarm(hour: 7, minute: 0, repeat: {Weekday.mon});

  test('쉬지 않으면 첫 회차까지 남은 시간', () {
    expect(
      AlarmSaveResult.of(oneShot, now, null),
      const AlarmSaveResult.ringsIn(Duration(minutes: 10)),
    );
  });

  test('쉬는 기간 안의 한 번 알람은 울리지 않는다', () {
    expect(
      AlarmSaveResult.of(oneShot, now, AlarmPause.today(now)),
      const AlarmSaveResult.pausedOut(),
    );
  });

  test('반복 알람은 쉬는 기간 뒤 첫 회차까지 센다', () {
    final pause = AlarmPause(from: DateTime(2026, 9, 28), until: DateTime(2026, 9, 28));
    expect(
      AlarmSaveResult.of(monday, now, pause),
      AlarmSaveResult.ringsIn(DateTime(2026, 10, 5, 7).difference(now)),
    );
  });

  test('꺼졌거나 지난 한 번 알람은 null', () {
    expect(AlarmSaveResult.of(monday.copyWith(enabled: false), now, AlarmPause.today(now)), isNull);
    expect(
      AlarmSaveResult.of(
        oneShot.copyWith(oneShotAt: DateTime(2026, 9, 27, 23)),
        now,
        AlarmPause.today(now),
      ),
      isNull,
    );
  });
}
