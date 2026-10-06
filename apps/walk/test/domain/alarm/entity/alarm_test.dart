import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';

void main() {
  test('Weekday.of 는 DateTime.weekday 와 대응한다', () {
    expect(Weekday.of(DateTime(2026, 9, 28)), Weekday.mon); // 월요일
    expect(Weekday.of(DateTime(2026, 9, 27)), Weekday.sun); // 일요일
  });

  test('반복 알람 JSON 왕복', () {
    const alarm = Alarm(
      id: 3,
      hour: 6,
      minute: 45,
      repeat: {Weekday.fri, Weekday.mon},
      label: '출근',
      silentWhenRingerMuted: true,
    );

    final decoded = Alarm.fromJson(
      jsonDecode(jsonEncode(alarm.toJson())) as Map<String, Object?>,
    );

    expect(decoded, alarm);
    expect(alarm.toJson()['repeat'], ['mon', 'fri']); // 요일 순서로 저장
  });

  test('1회성 알람 JSON 왕복은 oneShotAt 을 로컬 시각 그대로 되살린다', () {
    final alarm = Alarm(id: 1, hour: 7, minute: 0, enabled: false, oneShotAt: DateTime(2026, 9, 28, 7));

    final decoded = Alarm.fromJson(
      jsonDecode(jsonEncode(alarm.toJson())) as Map<String, Object?>,
    );

    expect(decoded, alarm);
    expect(decoded.oneShotAt!.isUtc, isFalse);
  });

  group('sound', () {
    Alarm roundTrip(Alarm alarm) =>
        Alarm.fromJson(jsonDecode(jsonEncode(alarm.toJson())) as Map<String, Object?>);

    test('기본은 시스템 기본 알람음', () {
      expect(const Alarm(hour: 7, minute: 0).sound, const AlarmSound.system());
      expect(Alarm.draft().sound, const AlarmSound.system());
    });

    test('JSON 에 sound 로 저장하고 3종 모두 되살린다', () {
      const sounds = [
        AlarmSound.system(),
        AlarmSound.bundled(BundledAlarmSounds.rising),
        AlarmSound.device(title: 'Morning Glory', path: '/data/app_flutter/alarm_sounds/1a2b.ogg'),
      ];
      for (final sound in sounds) {
        final alarm = Alarm(id: 2, hour: 6, minute: 30, sound: sound);

        expect(alarm.toJson()['sound'], sound.toJson());
        expect(roundTrip(alarm), alarm);
      }
    });

    test('sound 키가 없는 기존 알람은 시스템 기본으로 읽는다', () {
      final alarm = Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0, 'enabled': true});

      expect(alarm.sound, const AlarmSound.system());
    });

    test('sound 가 깨졌으면 알람은 살리고 소리만 시스템 기본으로 읽는다', () {
      final alarm = Alarm.fromJson(const {
        'id': 1,
        'hour': 7,
        'minute': 0,
        'sound': {'type': 'device', 'title': 'A'},
      });

      expect(alarm.sound, const AlarmSound.system());
    });
  });

  group('silentWhenRingerMuted', () {
    test('JSON 에 silentWhenRingerMuted 로 저장하고 vibrate 키는 쓰지 않는다', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 0, silentWhenRingerMuted: true);

      final json = alarm.toJson();

      expect(json['silentWhenRingerMuted'], isTrue);
      expect(json.containsKey('vibrate'), isFalse);
      expect(Alarm.fromJson(jsonDecode(jsonEncode(json)) as Map<String, Object?>), alarm);
    });

    test('옛 vibrate 키는 읽고 버린다', () {
      final alarm = Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0, 'vibrate': false});

      expect(alarm, const Alarm(id: 1, hour: 7, minute: 0, enabled: false));
    });
  });

  group('fromJson 기본값 · 깨진 값', () {
    test('enabled 가 없으면 꺼진 알람으로 읽는다', () {
      final alarm = Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0});

      expect(alarm.enabled, isFalse);
    });

    test('선택 필드가 없으면 반복 없음 · 라벨 없음 · 무음 모드 체크 끔 · oneShotAt 없음', () {
      final alarm = Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0});

      expect(alarm.repeat, isEmpty);
      expect(alarm.label, '');
      expect(alarm.silentWhenRingerMuted, isFalse);
      expect(alarm.oneShotAt, isNull);
    });

    // 저장소(PrefsAlarmRepository.load)가 던진 항목만 건너뛴다.
    test('모르는 요일 이름이면 던진다(저장소가 그 항목을 건너뛴다)', () {
      expect(
        () => Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0, 'repeat': ['funday']}),
        throwsA(anything),
      );
    });

    test('id · hour · minute 가 없으면 던진다', () {
      expect(() => Alarm.fromJson(const {'hour': 7, 'minute': 0}), throwsA(anything));
      expect(() => Alarm.fromJson(const {'id': 1, 'minute': 0}), throwsA(anything));
      expect(() => Alarm.fromJson(const {'id': 1, 'hour': 7}), throwsA(anything));
    });

    test('oneShotAt 이 날짜가 아니면 던진다', () {
      expect(
        () => Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0, 'oneShotAt': 'nope'}),
        throwsA(anything),
      );
    });
  });

  test('draft 는 07:00 · 반복 없음 · 무음 모드 체크 끔 · 저장 전 id', () {
    final draft = Alarm.draft();
    expect((draft.hour, draft.minute), (7, 0));
    expect(draft.isOneShot, isTrue);
    expect(draft.silentWhenRingerMuted, isFalse);
    expect(draft.id, Alarm.unsavedId);
  });
}
