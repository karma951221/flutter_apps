import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';

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
      vibrate: false,
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

  group('fromJson 기본값 · 깨진 값', () {
    test('enabled 가 없으면 꺼진 알람으로 읽는다', () {
      final alarm = Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0});

      expect(alarm.enabled, isFalse);
    });

    test('선택 필드가 없으면 반복 없음 · 라벨 없음 · 진동 켬 · oneShotAt 없음', () {
      final alarm = Alarm.fromJson(const {'id': 1, 'hour': 7, 'minute': 0});

      expect(alarm.repeat, isEmpty);
      expect(alarm.label, '');
      expect(alarm.vibrate, isTrue);
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

  test('draft 는 07:00 · 반복 없음 · 진동 켬 · 저장 전 id', () {
    final draft = Alarm.draft();
    expect((draft.hour, draft.minute), (7, 0));
    expect(draft.isOneShot, isTrue);
    expect(draft.vibrate, isTrue);
    expect(draft.id, Alarm.unsavedId);
  });
}
