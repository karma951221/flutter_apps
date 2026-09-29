import 'dart:convert';

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

  group('저장값이 깨져 있으면', () {
    test('깨진 JSON 이면 빈 목록 · 원본은 백업 키에', () async {
      const broken = '[{"id": 1, "hour": 7,';
      SharedPreferences.setMockInitialValues({PrefsAlarmRepository.key: broken});
      final prefs = await SharedPreferences.getInstance();

      expect(await PrefsAlarmRepository(prefs).load(), isEmpty);
      expect(prefs.getString(PrefsAlarmRepository.corruptKey), broken);
    });

    test('배열이 아닌 JSON 이어도 빈 목록 · 원본은 백업 키에', () async {
      const notList = '{"id": 1}';
      SharedPreferences.setMockInitialValues({PrefsAlarmRepository.key: notList});
      final prefs = await SharedPreferences.getInstance();

      expect(await PrefsAlarmRepository(prefs).load(), isEmpty);
      expect(prefs.getString(PrefsAlarmRepository.corruptKey), notList);
    });

    test('항목 하나가 깨져도 나머지 알람은 읽는다', () async {
      final raw = jsonEncode([
        const Alarm(id: 1, hour: 6, minute: 30, repeat: {Weekday.mon}).toJson(),
        {'id': 2, 'hour': 7, 'minute': 0, 'repeat': ['funday']}, // 모르는 요일
        {'hour': 8, 'minute': 0}, // id 없음
        {'id': 4, 'minute': 0}, // hour 없음
        {'id': 5, 'hour': 9, 'minute': 0, 'oneShotAt': 'not-a-date'}, // 시각 깨짐
        'not-an-object',
        null,
        const Alarm(id: 6, hour: 22, minute: 15, label: '잠').toJson(),
      ]);
      SharedPreferences.setMockInitialValues({PrefsAlarmRepository.key: raw});
      final prefs = await SharedPreferences.getInstance();

      final alarms = await PrefsAlarmRepository(prefs).load();

      expect(alarms, const [
        Alarm(id: 1, hour: 6, minute: 30, repeat: {Weekday.mon}),
        Alarm(id: 6, hour: 22, minute: 15, label: '잠'),
      ]);
      expect(prefs.getString(PrefsAlarmRepository.corruptKey), raw);
    });

    test('다음 깨짐이 백업을 덮어쓴다', () async {
      SharedPreferences.setMockInitialValues({
        PrefsAlarmRepository.key: 'second-broken',
        PrefsAlarmRepository.corruptKey: 'first-broken',
      });
      final prefs = await SharedPreferences.getInstance();

      await PrefsAlarmRepository(prefs).load();

      expect(prefs.getString(PrefsAlarmRepository.corruptKey), 'second-broken');
    });

    test('다음 저장은 원래 키를 정상으로 덮어쓰고 백업은 남긴다', () async {
      SharedPreferences.setMockInitialValues({PrefsAlarmRepository.key: 'broken'});
      final prefs = await SharedPreferences.getInstance();
      final repository = PrefsAlarmRepository(prefs);
      await repository.load();

      await repository.save([const Alarm(id: 1, hour: 7, minute: 0)]);

      expect(await PrefsAlarmRepository(prefs).load(), [const Alarm(id: 1, hour: 7, minute: 0)]);
      expect(prefs.getString(PrefsAlarmRepository.corruptKey), 'broken');
    });

    test('문자열이 아닌 값이 저장돼 있어도 던지지 않고 빈 목록', () async {
      SharedPreferences.setMockInitialValues({PrefsAlarmRepository.key: 42});
      final repository = PrefsAlarmRepository(await SharedPreferences.getInstance());

      expect(await repository.load(), isEmpty);
    });

    test('깨지지 않았으면 백업 키를 건드리지 않는다', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await PrefsAlarmRepository(prefs).save([const Alarm(id: 1, hour: 7, minute: 0)]);

      await PrefsAlarmRepository(prefs).load();

      expect(prefs.getString(PrefsAlarmRepository.corruptKey), isNull);
    });
  });
}
