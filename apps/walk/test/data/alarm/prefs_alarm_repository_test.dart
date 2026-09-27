import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/alarm/prefs_alarm_repository.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';

void main() {
  test('저장한 적이 없으면 빈 목록', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsAlarmRepository(await SharedPreferences.getInstance());

    expect(await repository.load(), isEmpty);
  });

  test('저장한 목록을 그대로 읽는다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final alarms = [
      const Alarm(id: 1, hour: 6, minute: 30, repeat: {Weekday.mon, Weekday.wed}, label: '운동'),
      Alarm(id: 2, hour: 22, minute: 0, vibrate: false, oneShotAt: DateTime(2026, 9, 28, 22)),
    ];

    await PrefsAlarmRepository(prefs).save(alarms);

    // 새 인스턴스로 읽어 디스크 형식을 거친다.
    expect(await PrefsAlarmRepository(prefs).load(), alarms);
    expect(prefs.getString(PrefsAlarmRepository.key), isNotNull);
  });

  test('빈 목록으로 저장하면 비운다', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsAlarmRepository(await SharedPreferences.getInstance());
    await repository.save([const Alarm(id: 1, hour: 7, minute: 0)]);

    await repository.save([]);

    expect(await repository.load(), isEmpty);
  });
}
