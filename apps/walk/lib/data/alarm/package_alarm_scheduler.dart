import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:alarm/alarm.dart' as pkg;
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../domain/alarm/entity/alarm.dart';
import '../../domain/alarm/entity/alarm_sound.dart';
import '../../domain/alarm/scheduler/alarm_scheduler.dart';
import '../../domain/alarm/upcoming_triggers.dart';

/// 알림에 쓰는 문구. 예약은 화면 밖에서도 일어나 `BuildContext` 대신 기기 언어로 찾는다.
/// [locale] 은 본문 시각(`오전 7:00`)을 쓰는 `intl` 로캘이다.
typedef AlarmNotificationTexts = ({
  String locale,
  String defaultTitle,
  String stop,
  String snooze,
});

/// [`alarm`](https://pub.dev/packages/alarm) 패키지 래퍼.
@LazySingleton(as: AlarmScheduler)
class PackageAlarmScheduler implements AlarmScheduler {
  /// 울림 볼륨과 페이드. 지문에도 들어가 바꾸면 이미 걸린 회차가 다시 걸린다.
  static const _volume = 0.8;
  static const _fadeDuration = Duration(seconds: 3);

  /// 알림 작은 아이콘 — `res/drawable/ic_stat_alarm.xml`(흰 단색 알람시계). 포크가 이 이름을
  /// `getIdentifier` 로 찾으니 `res/raw/keep.xml` 도 같은 이름을 남긴다(컨벤션 테스트가 본다).
  static const notificationIcon = 'ic_stat_alarm';

  @override
  Future<Map<int, ScheduledRing>> scheduled() async => {
    for (final settings in await pkg.Alarm.getAlarms()) settings.id: ringOf(settings),
  };

  @override
  String signatureOf(Alarm alarm) => signatureFor(alarm);

  /// 걸린 예약의 시각과 payload(`'<alarmId>|<지문>'`)의 지문. 지문 없는 옛 payload(`'<alarmId>'`)는 빈 지문.
  static ScheduledRing ringOf(pkg.AlarmSettings settings) {
    final payload = settings.payload ?? '';
    final bar = payload.indexOf('|');
    return (at: settings.dateTime, signature: bar < 0 ? '' : payload.substring(bar + 1));
  }

  /// 울림에 영향을 주는 값(소리 · 대체음 · 무음 모드 체크 · 라벨 · 볼륨 · 페이드 · 스누즈 · 알림
  /// 아이콘)을 정해진 순서로 이은 문자열의 fnv1a32(8자리 hex). 알림 문구(l10n)와 시각은 넣지 않는다
  /// — 로캘이 바뀌어도 다시 걸지 않고, 시각은 따로 비교한다. 기기 알람음은 복사본 유무가 아니라 저장된 경로를 넣는다.
  static String signatureFor(Alarm alarm) => _fnv1a32(
    [
      switch (alarm.sound) {
        SystemAlarmSound() => 'system',
        BundledAlarmSound(:final asset) => 'bundled:$asset',
        DeviceAlarmSound(:final path) => 'device:$path',
      },
      BundledAlarmSounds.beep,
      // 이름을 붙인다 — 웨이브 1 전에는 같은 자리에 vibrate(true/false)가 있었다. 값만 넣으면
      // 진동을 끈 옛 알람의 지문이 그대로라, 진동 없이 걸린 회차를 다시 걸지 않는다.
      'silentWhenRingerMuted:${alarm.silentWhenRingerMuted}',
      alarm.label,
      _volume,
      _fadeDuration.inMilliseconds,
      alarmSnoozeDuration.inSeconds,
      // 알림 아이콘을 넣기 전에 걸린 회차는 icon 이 없어 포크가 적응형 런처 아이콘으로 알림을 만든다
      // (안드로이드 8.0 은 알림이 실패할 수 있다). 이름을 넣어 올린 뒤 한 번 다시 걸게 한다.
      'icon:$notificationIcon',
    ].join('\u0000'),
  );

  static String _fnv1a32(String input) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

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

  /// 패키지 `checkAlarm` 은 저장된 예약 중 아직 오지 않은 것을 모두 다시 `set` 한다.
  @override
  Future<void> rearmAll() => pkg.Alarm.checkAlarm();

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
    AlarmNotificationTexts texts, {
    bool Function(String path) fileExists = _exists,
  }) => pkg.AlarmSettings(
    id: packageId,
    dateTime: at,
    // null 이면 포크가 기기의 기본 알람음으로 울린다.
    assetAudioPath: switch (alarm.sound) {
      SystemAlarmSound() => null,
      BundledAlarmSound(:final asset) => asset,
      DeviceAlarmSound(:final path) => fileExists(path) ? path : null,
    },
    // 위 소리로 울리지 못하면(파일 손상 · 기기 기본음 없음) 비프로 울린다.
    androidFallbackAudioPath: BundledAlarmSounds.beep,
    loopAudio: true,
    // 진동은 항상 켠다. 폰이 무음 · 진동 모드일 때 소리를 낼지는 포크가 울리는 순간 정한다.
    vibrate: true,
    androidSilentWhenRingerMuted: alarm.silentWhenRingerMuted,
    volumeSettings: pkg.VolumeSettings.fade(
      volume: _volume,
      fadeDuration: _fadeDuration,
      // 울릴 때 · 끌 때 알람 볼륨을 바꾸며 시스템 볼륨 패널이 뜨지 않게 한다.
      showSystemUI: false,
    ),
    // NotificationOnKillService 를 선언하지 않는다. 안드로이드는 앱이 죽어도 AlarmManager 가 울린다.
    warningNotificationOnKill: false,
    androidFullScreenIntent: true,
    // 기상 알람이라 앱을 최근 앱에서 밀어 없애도 계속 울려야 한다.
    androidStopAlarmOnTermination: false,
    // 여러 알람이 같은 시각이어도 서로 지우지 않고 차례로 울린다.
    allowSameSecondScheduling: true,
    androidSnoozeDuration: alarmSnoozeDuration,
    notificationSettings: pkg.NotificationSettings(
      title: alarm.label.isEmpty ? texts.defaultTitle : alarm.label,
      body: _time(texts.locale, alarm.hour, alarm.minute),
      stopButton: texts.stop,
      androidSnoozeButton: texts.snooze,
      // 적응형 런처 아이콘은 상태바에서 덩어리로 보인다.
      icon: notificationIcon,
    ),
    payload: '${alarm.id}|${signatureFor(alarm)}',
  );

  static bool _exists(String path) => File(path).existsSync();

  /// 기기 언어 시각 — `오전 7:00`, `7:00 AM`. data 계층이라 `MaterialLocalizations` 대신
  /// `intl` 을 쓴다. 날짜 기호가 아직 없으면(로컬라이제이션 로드 전) `07:00` 으로 둔다.
  static String _time(String locale, int hour, int minute) {
    try {
      return DateFormat.jm(locale).format(DateTime(2000, 1, 1, hour, minute));
    } on Object {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
  }

  static AlarmNotificationTexts _texts() {
    final locale = basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    );
    final l10n = lookupAppLocalizations(locale);
    return (
      locale: l10n.localeName,
      defaultTitle: l10n.walkAlarmDefaultTitle,
      stop: l10n.walkAlarmStop,
      snooze: l10n.walkAlarmSnooze,
    );
  }
}
