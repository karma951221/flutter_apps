import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/data/alarm/package_alarm_scheduler.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/upcoming_triggers.dart';

void main() {
  const texts = (locale: 'ko', defaultTitle: '알람', stop: '알람 끄기', snooze: '5분 뒤 다시 울림');
  final at = DateTime(2026, 9, 29, 7, 5);

  setUpAll(() async {
    await initializeDateFormatting('ko');
    await initializeDateFormatting('en');
    await initializeDateFormatting('ja');
  });

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
    expect(settings.notificationSettings.body, '오전 7:05');
    expect(settings.notificationSettings.stopButton, '알람 끄기');
    expect(settings.notificationSettings.androidSnoozeButton, '5분 뒤 다시 울림');
    expect(settings.payload, '3');
  });

  test('라벨이 없으면 기본 제목', () {
    const alarm = Alarm(id: 3, hour: 7, minute: 5);

    final settings = PackageAlarmScheduler.settingsFor(312, at, alarm, texts);

    expect(settings.notificationSettings.title, '알람');
  });

  test('본문 시각은 기기 언어를 따른다', () {
    const alarm = Alarm(id: 3, hour: 21, minute: 45);

    String body(String locale) => PackageAlarmScheduler.settingsFor(
      312,
      at,
      alarm,
      (locale: locale, defaultTitle: '', stop: '', snooze: ''),
    ).notificationSettings.body;

    expect(body('ko'), '오후 9:45');
    expect(body('en'), '9:45\u202fPM');
    expect(body('ja'), '21:45');
  });

  test('버튼 문구는 각 언어의 끄기 · 다시 울림', () {
    final ko = lookupAppLocalizations(const Locale('ko'));
    final en = lookupAppLocalizations(const Locale('en'));
    final ja = lookupAppLocalizations(const Locale('ja'));
    expect((ko.walkAlarmStop, ko.walkAlarmSnooze), ('알람 끄기', '5분 뒤 다시 울림'));
    expect((en.walkAlarmStop, en.walkAlarmSnooze), ('Stop alarm', 'Snooze 5 min'));
    expect((ja.walkAlarmStop, ja.walkAlarmSnooze), ('アラームを止める', '5分後に再通知'));
  });
}
