import 'package:alarm/alarm.dart';
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

  AlarmMoved moved(AlarmEventCause cause) => AlarmMoved(
    id: 312,
    cause: cause,
    recordedAt: DateTime(2026, 10, 6, 7, 5, 30),
    nextRingAt: next,
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
}
