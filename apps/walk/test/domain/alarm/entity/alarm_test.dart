import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_options.dart';
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

    final decoded = Alarm.fromJson(jsonDecode(jsonEncode(alarm.toJson())) as Map<String, Object?>);

    expect(decoded, alarm);
    expect(alarm.toJson()['repeat'], ['mon', 'fri']); // 요일 순서로 저장
  });

  test('1회성 알람 JSON 왕복은 oneShotAt 을 로컬 시각 그대로 되살린다', () {
    final alarm = Alarm(
      id: 1,
      hour: 7,
      minute: 0,
      enabled: false,
      oneShotAt: DateTime(2026, 9, 28, 7),
    );

    final decoded = Alarm.fromJson(jsonDecode(jsonEncode(alarm.toJson())) as Map<String, Object?>);

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
        () => Alarm.fromJson(const {
          'id': 1,
          'hour': 7,
          'minute': 0,
          'repeat': ['funday'],
        }),
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

  group('울림 세부 · 건너뛰기', () {
    Alarm roundTrip(Alarm alarm) =>
        Alarm.fromJson(jsonDecode(jsonEncode(alarm.toJson())) as Map<String, Object?>);

    test('기본은 볼륨 80 · 점점 커지기 끔 · 스누즈 5분 무제한 · 자동 멈춤 없음 · 미리 알림 끔 · 건너뛰기 없음', () {
      const alarm = Alarm(hour: 7, minute: 0);

      expect(alarm.volumePercent, 80);
      expect(alarm.fadeSeconds, 0);
      expect(alarm.snoozeMinutes, 5);
      expect(alarm.snoozeLimit, isNull);
      expect(alarm.autoStopMinutes, isNull);
      expect(alarm.remindBefore, isFalse);
      expect(alarm.skippedAt, isNull);
      expect(Alarm.draft(), const Alarm(hour: 7, minute: 0));
    });

    test('기본값은 선택지 안에 있다', () {
      expect(AlarmOptions.volumePercents, contains(AlarmOptions.defaultVolumePercent));
      expect(AlarmOptions.volumePercents, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]);
      expect(AlarmOptions.fadeSeconds, [0, 30, 60]);
      expect(AlarmOptions.snoozeMinutes, [5, 10, 15]);
      expect(AlarmOptions.snoozeLimits, [null, 3]);
      expect(AlarmOptions.autoStopMinutes, [null, 5, 10, 15]);
    });

    test('새 필드를 JSON 키 그대로 저장하고 되살린다(skippedAt 은 로컬 ISO)', () {
      final alarm = Alarm(
        id: 2,
        hour: 7,
        minute: 0,
        repeat: const {Weekday.mon},
        volumePercent: 40,
        fadeSeconds: 30,
        snoozeMinutes: 15,
        snoozeLimit: 3,
        autoStopMinutes: 10,
        remindBefore: true,
        skippedAt: DateTime(2026, 10, 5, 7),
      );

      final json = alarm.toJson();

      expect(json['volumePercent'], 40);
      expect(json['fadeSeconds'], 30);
      expect(json['snoozeMinutes'], 15);
      expect(json['snoozeLimit'], 3);
      expect(json['autoStopMinutes'], 10);
      expect(json['remindBefore'], isTrue);
      expect(json['skippedAt'], '2026-10-05T07:00:00.000');
      final decoded = roundTrip(alarm);
      expect(decoded, alarm);
      expect(decoded.skippedAt!.isUtc, isFalse);
    });

    test('null 값(무제한 · 안 함 · 건너뛰기 없음)도 왕복한다', () {
      const alarm = Alarm(id: 2, hour: 7, minute: 0, snoozeMinutes: 10, autoStopMinutes: null);

      expect(roundTrip(alarm), alarm);
      expect(roundTrip(alarm).snoozeLimit, isNull);
    });

    test('키가 없는 기존 알람은 기본값으로 읽는다', () {
      final alarm = Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0, 'enabled': true});

      expect(alarm, const Alarm(id: 1, hour: 7, minute: 0));
    });

    test('선택지 밖이거나 타입이 다르면 기본값으로 읽는다', () {
      final alarm = Alarm.fromJson(const {
        'id': 1,
        'hour': 7,
        'minute': 0,
        'enabled': true,
        'volumePercent': 0,
        'fadeSeconds': 45,
        'snoozeMinutes': 7,
        'snoozeLimit': 5,
        'autoStopMinutes': 3,
        'remindBefore': 'yes',
        'skippedAt': 'nope',
      });

      expect(alarm, const Alarm(id: 1, hour: 7, minute: 0));
    });

    test('볼륨은 10 단위만 받는다', () {
      for (final (raw, read) in [(10, 10), (100, 100), (55, 80), (110, 80), ('80', 80)]) {
        final alarm = Alarm.fromJson({'id': 1, 'hour': 7, 'minute': 0, 'volumePercent': raw});
        expect(alarm.volumePercent, read, reason: '$raw');
      }
    });
  });

  test('draft 는 07:00 · 반복 없음 · 무음 모드 체크 끔 · 저장 전 id', () {
    final draft = Alarm.draft();
    expect((draft.hour, draft.minute), (7, 0));
    expect(draft.isOneShot, isTrue);
    expect(draft.silentWhenRingerMuted, isFalse);
    expect(draft.id, Alarm.unsavedId);
  });

  group('duplicate', () {
    test('반복 알람은 같은 설정의 저장 전 알람 — id · 건너뛰기만 비운다', () {
      final alarm = Alarm(
        id: 4,
        hour: 6,
        minute: 45,
        repeat: const {Weekday.mon, Weekday.fri},
        label: '출근',
        silentWhenRingerMuted: true,
        sound: const AlarmSound.bundled(BundledAlarmSounds.rising),
        enabled: false,
        volumePercent: 50,
        fadeSeconds: 0,
        snoozeMinutes: 10,
        snoozeLimit: 3,
        autoStopMinutes: 5,
        remindBefore: true,
        skippedAt: DateTime(2026, 10, 9, 6, 45),
      );

      final copy = alarm.duplicate();

      expect(copy.id, Alarm.unsavedId);
      expect(copy.skippedAt, isNull);
      expect(copy, alarm.copyWith(id: Alarm.unsavedId, skippedAt: null));
    });

    test('1회성은 지난 울릴 시각(oneShotAt)도 비운다', () {
      final alarm = Alarm(
        id: 2,
        hour: 7,
        minute: 0,
        label: '약',
        oneShotAt: DateTime(2026, 10, 1, 7),
      );

      final copy = alarm.duplicate();

      expect(copy, const Alarm(hour: 7, minute: 0, label: '약'));
      expect(copy.oneShotAt, isNull);
    });
  });
}
