import 'package:alarm/alarm.dart';
// 호스트가 보내는 wire 형태를 그대로 만들어 보기 위해서다.
// ignore: implementation_imports
import 'package:alarm/src/generated/platform_bindings.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// 포크(`third_party/alarm/lib/model/alarm_event.dart`)에서 바꾼 것.
/// `Alarm._applyMove` 가 Dart 저장소를 맞출 때 쓰는 규칙이다(FORK.md).
void main() {
  final next = DateTime(2026, 10, 6, 7, 10);

  AlarmSettings settings({int? limit, int count = 0}) => AlarmSettings(
    id: 312,
    dateTime: DateTime(2026, 10, 6, 7, 5),
    volumeSettings: VolumeSettings.fixed(),
    notificationSettings: const NotificationSettings(
      title: '알람',
      body: '오전 7:05',
      androidSnoozeButton: '5분 뒤',
    ),
    androidSnoozeDuration: const Duration(minutes: 5),
    androidSnoozeLimit: limit,
    snoozeCount: count,
  );

  AlarmMoved moved(AlarmEventCause cause, {int? snoozeCount}) => AlarmMoved(
    id: 312,
    cause: cause,
    recordedAt: DateTime(2026, 10, 6, 7, 5, 30),
    nextRingAt: next,
    snoozeCount: snoozeCount,
  );

  group('AlarmMoved.applyTo', () {
    test('스누즈는 시각을 옮기고 횟수를 올린다', () {
      final applied = moved(AlarmEventCause.snooze).applyTo(settings());

      expect(applied.dateTime, next);
      expect(applied.snoozeCount, 1);
    });

    test('한도에 닿은 스누즈는 다음 울림의 스누즈를 끈다', () {
      final applied = moved(
        AlarmEventCause.snooze,
      ).applyTo(settings(limit: 3, count: 2));

      expect(applied.snoozeCount, 3);
      expect(applied.androidSnoozeDuration, isNull);
      expect(applied.notificationSettings.androidSnoozeButton, isNull);
    });

    test('플랫폼 거부로 옮긴 것은 시각만 옮긴다', () {
      final applied = moved(
        AlarmEventCause.platformRefusal,
      ).applyTo(settings(limit: 3, count: 2));

      expect(applied, settings(limit: 3, count: 2).copyWith(dateTime: next));
    });
  });

  group('호스트가 센 횟수', () {
    test('wire 의 snoozeCount 를 그대로 싣는다', () {
      final event = AlarmEvent.fromWire(
        AlarmEventWire(
          alarmId: 312,
          verb: AlarmEventVerbWire.moved,
          cause: AlarmEventCauseWire.snooze,
          atMillis: next.millisecondsSinceEpoch,
          recordedAtMillis: next.millisecondsSinceEpoch - 1000,
          snoozeCount: 3,
        ),
      );

      expect(event, isA<AlarmMoved>());
      expect((event as AlarmMoved).snoozeCount, 3);
    });

    test('표식 하나가 여러 번의 스누즈를 대신하면 호스트의 횟수를 따른다', () {
      // 앱이 꺼진 채 알림에서 세 번 스누즈하면 표식은 마지막 것 하나만 남는다.
      final applied = moved(
        AlarmEventCause.snooze,
        snoozeCount: 3,
      ).applyTo(settings(limit: 3));

      expect(applied.dateTime, next);
      expect(applied.snoozeCount, 3);
      expect(applied.androidSnoozeDuration, isNull);
      expect(applied.notificationSettings.androidSnoozeButton, isNull);
    });

    test('한도 전이면 호스트의 횟수만 따르고 스누즈는 남긴다', () {
      final applied = moved(
        AlarmEventCause.snooze,
        snoozeCount: 2,
      ).applyTo(settings(limit: 3));

      expect(applied.snoozeCount, 2);
      expect(applied.androidSnoozeDuration, const Duration(minutes: 5));
      expect(applied.notificationSettings.androidSnoozeButton, '5분 뒤');
    });

    test('같은 표식을 다시 적용해도 두 번 세지 않는다', () {
      final event = moved(AlarmEventCause.snooze, snoozeCount: 2);

      final once = event.applyTo(settings(limit: 5));
      final twice = event.applyTo(once);

      expect(twice, once);
      expect(twice.snoozeCount, 2);
    });

    test('횟수가 없는 옛 표식은 Dart 가 하나 센다', () {
      final applied = moved(AlarmEventCause.snooze).applyTo(settings(count: 1));

      expect(applied.snoozeCount, 2);
    });
  });
}
