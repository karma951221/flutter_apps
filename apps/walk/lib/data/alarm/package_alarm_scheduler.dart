import 'dart:ui';

import 'package:alarm/alarm.dart' as pkg;
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:l10n/l10n.dart';

import '../../domain/alarm/entity/alarm.dart';
import '../../domain/alarm/scheduler/alarm_scheduler.dart';
import '../../domain/alarm/upcoming_triggers.dart';

/// 알림에 쓰는 문구. 예약은 화면 밖에서도 일어나 `BuildContext` 대신 기기 언어로 찾는다.
typedef AlarmNotificationTexts = ({String defaultTitle, String stop, String snooze});

/// [`alarm`](https://pub.dev/packages/alarm) 패키지 래퍼.
@LazySingleton(as: AlarmScheduler)
class PackageAlarmScheduler implements AlarmScheduler {
  static const assetAudioPath = 'assets/alarm/default.wav';

  @override
  Future<Map<int, DateTime>> scheduled() async => {
    for (final settings in await pkg.Alarm.getAlarms()) settings.id: settings.dateTime,
  };

  /// 울리는 알람은 시각이 지난 것뿐이라 그것만 플랫폼에 묻는다.
  @override
  Future<Set<int>> ringingIds() async {
    final now = DateTime.now();
    return {
      for (final settings in await pkg.Alarm.getAlarms())
        if (!settings.dateTime.isAfter(now) && await pkg.Alarm.isRinging(settings.id)) settings.id,
    };
  }

  @override
  Future<void> schedule(int packageId, DateTime at, Alarm alarm) async {
    await pkg.Alarm.set(alarmSettings: settingsFor(packageId, at, alarm, _texts()));
  }

  @override
  Future<void> cancel(int packageId) async {
    await pkg.Alarm.stop(packageId);
  }

  @override
  Future<void> stop(int packageId) async {
    await pkg.Alarm.stop(packageId);
  }

  static pkg.AlarmSettings settingsFor(
    int packageId,
    DateTime at,
    Alarm alarm,
    AlarmNotificationTexts texts,
  ) => pkg.AlarmSettings(
    id: packageId,
    dateTime: at,
    assetAudioPath: assetAudioPath,
    loopAudio: true,
    vibrate: alarm.vibrate,
    volumeSettings: pkg.VolumeSettings.fade(
      volume: 0.8,
      fadeDuration: const Duration(seconds: 3),
    ),
    // NotificationOnKillService 를 선언하지 않는다. 안드로이드는 앱이 죽어도 AlarmManager 가 울린다.
    warningNotificationOnKill: false,
    androidFullScreenIntent: true,
    // 여러 알람이 같은 시각이어도 서로 지우지 않고 차례로 울린다.
    allowSameSecondScheduling: true,
    androidSnoozeDuration: alarmSnoozeDuration,
    notificationSettings: pkg.NotificationSettings(
      title: alarm.label.isEmpty ? texts.defaultTitle : alarm.label,
      body: _hhmm(alarm.hour, alarm.minute),
      stopButton: texts.stop,
      androidSnoozeButton: texts.snooze,
    ),
    payload: '${alarm.id}',
  );

  static String _hhmm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static AlarmNotificationTexts _texts() {
    final locale = basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    );
    final l10n = lookupAppLocalizations(locale);
    return (
      defaultTitle: l10n.walkAlarmDefaultTitle,
      stop: l10n.walkAlarmStop,
      snooze: l10n.walkAlarmSnooze,
    );
  }
}
