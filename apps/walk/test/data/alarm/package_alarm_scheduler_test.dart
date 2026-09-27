import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/alarm/package_alarm_scheduler.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/upcoming_triggers.dart';

void main() {
  const texts = (defaultTitle: '알람', stop: '끄기', snooze: '5분 뒤');
  final at = DateTime(2026, 9, 29, 7, 5);

  test('AlarmSettings 는 스펙 §5 대로 만든다', () {
    const alarm = Alarm(id: 3, hour: 7, minute: 5, label: '출근', vibrate: false);

    final settings = PackageAlarmScheduler.settingsFor(312, at, alarm, texts);

    expect(settings.id, 312);
    expect(settings.dateTime, at);
    expect(settings.assetAudioPath, PackageAlarmScheduler.assetAudioPath);
    expect(settings.loopAudio, isTrue);
    expect(settings.vibrate, isFalse);
    expect(settings.volumeSettings.volume, 0.8);
    expect(settings.volumeSettings.fadeDuration, const Duration(seconds: 3));
    expect(settings.androidFullScreenIntent, isTrue);
    expect(settings.androidStopAlarmOnTermination, isFalse);
    expect(settings.androidSnoozeDuration, alarmSnoozeDuration);
    expect(settings.allowSameSecondScheduling, isTrue);
    expect(settings.notificationSettings.title, '출근');
    expect(settings.notificationSettings.body, '07:05');
    expect(settings.notificationSettings.stopButton, '끄기');
    expect(settings.notificationSettings.androidSnoozeButton, '5분 뒤');
    expect(settings.payload, '3');
  });

  test('라벨이 없으면 기본 제목', () {
    const alarm = Alarm(id: 3, hour: 7, minute: 5);

    final settings = PackageAlarmScheduler.settingsFor(312, at, alarm, texts);

    expect(settings.notificationSettings.title, '알람');
  });
}
