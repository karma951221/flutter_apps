import 'dart:convert';

import 'package:alarm/alarm.dart' as pkg;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/data/alarm/package_alarm_scheduler.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';

void main() {
  final AlarmNotificationTexts texts = (
    locale: 'ko',
    defaultTitle: '알람',
    stop: '알람 끄기',
    snooze: (int minutes) => '$minutes분 뒤 다시 울림',
  );
  final at = DateTime(2026, 9, 29, 7, 5);

  setUpAll(() async {
    await initializeDateFormatting('ko');
    await initializeDateFormatting('en');
    await initializeDateFormatting('ja');
  });

  test('AlarmSettings 는 스펙 §5 대로 만든다', () {
    const alarm = Alarm(id: 3, hour: 7, minute: 5, label: '출근', silentWhenRingerMuted: true);

    final settings = PackageAlarmScheduler.settingsFor(312, at, alarm, texts);

    expect(settings.id, 312);
    expect(settings.dateTime, at);
    expect(settings.assetAudioPath, isNull);
    expect(settings.androidFallbackAudioPath, BundledAlarmSounds.beep);
    expect(settings.loopAudio, isTrue);
    expect(settings.vibrate, isTrue);
    expect(settings.androidSilentWhenRingerMuted, isTrue);
    expect(settings.volumeSettings.volume, 0.8);
    expect(settings.volumeSettings.fadeDuration, isNull);
    expect(settings.volumeSettings.showSystemUI, isFalse);
    expect(settings.androidFullScreenIntent, isTrue);
    expect(settings.androidStopAlarmOnTermination, isFalse);
    expect(settings.androidSnoozeDuration, const Duration(minutes: 5));
    expect(settings.androidSnoozeLimit, isNull);
    expect(settings.snoozeCount, 0);
    expect(settings.androidAutoStopAfter, isNull);
    expect(settings.allowSameSecondScheduling, isTrue);
    expect(settings.notificationSettings.title, '출근');
    expect(settings.notificationSettings.body, '오전 7:05');
    expect(settings.notificationSettings.stopButton, '알람 끄기');
    expect(settings.notificationSettings.androidSnoozeButton, '5분 뒤 다시 울림');
    expect(settings.payload, '3|${PackageAlarmScheduler.signatureFor(alarm)}');
  });

  test('진동은 항상 켜고, 무음 모드 체크는 알람 값을 그대로 넘긴다', () {
    for (final silent in [false, true]) {
      final settings = PackageAlarmScheduler.settingsFor(
        312,
        at,
        Alarm(id: 3, hour: 7, minute: 5, silentWhenRingerMuted: silent),
        texts,
      );
      expect(settings.vibrate, isTrue, reason: '$silent');
      expect(settings.androidSilentWhenRingerMuted, silent);
    }
  });

  test('알림 작은 아이콘은 흰 단색 알람시계 drawable 이다', () {
    const alarm = Alarm(id: 3, hour: 7, minute: 5);

    final settings = PackageAlarmScheduler.settingsFor(312, at, alarm, texts);

    expect(settings.notificationSettings.icon, 'ic_stat_alarm');
    expect(PackageAlarmScheduler.notificationIcon, 'ic_stat_alarm');
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
      (locale: locale, defaultTitle: '', stop: '', snooze: (_) => ''),
    ).notificationSettings.body;

    expect(body('ko'), '오후 9:45');
    expect(body('en'), '9:45\u202fPM');
    expect(body('ja'), '21:45');
  });

  test('버튼 문구는 각 언어의 끄기 · 다시 울림', () {
    final ko = lookupAppLocalizations(const Locale('ko'));
    final en = lookupAppLocalizations(const Locale('en'));
    final ja = lookupAppLocalizations(const Locale('ja'));
    expect((ko.walkAlarmStop, ko.walkAlarmSnooze(10)), ('알람 끄기', '10분 뒤 다시 울림'));
    expect((en.walkAlarmStop, en.walkAlarmSnooze(10)), ('Stop alarm', 'Snooze 10 min'));
    expect((ja.walkAlarmStop, ja.walkAlarmSnooze(10)), ('アラームを止める', '10分後に再通知'));
  });

  group('울림 세부', () {
    pkg.AlarmSettings settings(Alarm alarm, {int snoozeCount = 0}) =>
        PackageAlarmScheduler.settingsFor(312, at, alarm, texts, snoozeCount: snoozeCount);
    const base = Alarm(id: 3, hour: 7, minute: 5);

    test('점점 커지기를 끄면 처음부터 그 볼륨(fixed)', () {
      final volume = settings(base.copyWith(volumePercent: 40)).volumeSettings;

      expect(volume.volume, 0.4);
      expect(volume.fadeDuration, isNull);
      expect(volume.fadeSteps, isEmpty);
      expect(volume.showSystemUI, isFalse);
    });

    test('점점 커지기를 켜면 그 시간 동안 그 볼륨까지(fade)', () {
      final volume = settings(base.copyWith(volumePercent: 100, fadeSeconds: 60)).volumeSettings;

      expect(volume.volume, 1.0);
      expect(volume.fadeDuration, const Duration(seconds: 60));
      expect(volume.showSystemUI, isFalse);
    });

    test('스누즈 간격은 알람 값이고 버튼 문구에 그 분을 넣는다', () {
      final s = settings(base.copyWith(snoozeMinutes: 15));

      expect(s.androidSnoozeDuration, const Duration(minutes: 15));
      expect(s.notificationSettings.androidSnoozeButton, '15분 뒤 다시 울림');
    });

    test('스누즈 한도와 지금까지 센 횟수를 넘긴다 — 한도 전이면 스누즈가 남는다', () {
      final s = settings(base.copyWith(snoozeLimit: 3), snoozeCount: 2);

      expect(s.androidSnoozeLimit, 3);
      expect(s.snoozeCount, 2);
      expect(s.androidSnoozeDuration, const Duration(minutes: 5));
      expect(s.notificationSettings.androidSnoozeButton, isNotNull);
    });

    test('횟수가 한도에 닿으면 스누즈 간격 · 버튼이 모두 없다', () {
      final s = settings(base.copyWith(snoozeLimit: 3), snoozeCount: 3);

      expect(s.snoozeCount, 3);
      expect(s.androidSnoozeDuration, isNull);
      expect(s.notificationSettings.androidSnoozeButton, isNull);
    });

    test('무제한이면 횟수와 상관없이 스누즈가 남는다', () {
      final s = settings(base, snoozeCount: 99);

      expect(s.androidSnoozeLimit, isNull);
      expect(s.androidSnoozeDuration, const Duration(minutes: 5));
    });

    test('자동 멈춤은 분을 Duration 으로, 안 함이면 null', () {
      expect(settings(base.copyWith(autoStopMinutes: 10)).androidAutoStopAfter, const Duration(minutes: 10));
      expect(settings(base).androidAutoStopAfter, isNull);
    });

    test('포크 nextAfterSnooze 와 같은 결과 — 한도 3 에서 세 번째 스누즈 뒤 스누즈 없음', () {
      final alarm = base.copyWith(snoozeLimit: 3);
      final next = at.add(const Duration(minutes: 5));
      for (final count in [1, 2, 3]) {
        final fromFork = settings(alarm, snoozeCount: count - 1).nextAfterSnooze(next);
        final fromApp = PackageAlarmScheduler.settingsFor(312, next, alarm, texts, snoozeCount: count);
        expect(
          (fromApp.snoozeCount, fromApp.androidSnoozeDuration, fromApp.notificationSettings.androidSnoozeButton),
          (fromFork.snoozeCount, fromFork.androidSnoozeDuration, fromFork.notificationSettings.androidSnoozeButton),
          reason: '$count',
        );
      }
    });
  });

  group('소리', () {
    String? audio(AlarmSound sound, {bool exists = true}) => PackageAlarmScheduler.settingsFor(
      312,
      at,
      Alarm(id: 3, hour: 7, minute: 5, sound: sound),
      texts,
      fileExists: (_) => exists,
    ).assetAudioPath;

    test('시스템 기본음은 경로 없이 건다', () {
      expect(audio(const AlarmSound.system()), isNull);
    });

    test('내장음은 에셋 경로로 건다', () {
      expect(audio(const AlarmSound.bundled(BundledAlarmSounds.chime)), BundledAlarmSounds.chime);
    });

    test('기기 알람음은 복사본이 있으면 그 경로, 없으면 시스템 기본음', () {
      const sound = AlarmSound.device(title: 'Oxygen', path: '/data/alarm_sounds/a.ogg');
      expect(audio(sound), '/data/alarm_sounds/a.ogg');
      expect(audio(sound, exists: false), isNull);
    });

    test('대체음은 소리와 상관없이 항상 비프', () {
      for (final sound in [
        const AlarmSound.system(),
        const AlarmSound.bundled(BundledAlarmSounds.rising),
        const AlarmSound.device(title: 'Oxygen', path: '/nope.ogg'),
      ]) {
        final settings = PackageAlarmScheduler.settingsFor(
          312,
          at,
          Alarm(id: 3, hour: 7, minute: 5, sound: sound),
          texts,
          fileExists: (_) => false,
        );
        expect(settings.androidFallbackAudioPath, BundledAlarmSounds.beep, reason: '$sound');
      }
    });
  });

  group('지문', () {
    const base = Alarm(id: 3, hour: 7, minute: 5, label: '출근');
    String sig(Alarm alarm) => PackageAlarmScheduler.signatureFor(alarm);

    test('같은 입력이면 같은 지문(8자리 hex)', () {
      expect(sig(base), sig(base.copyWith()));
      expect(sig(base), matches(RegExp(r'^[0-9a-f]{8}$')));
    });

    test('소리 · 무음 모드 체크 · 라벨이 바뀌면 지문이 바뀐다', () {
      final variants = [
        base,
        base.copyWith(sound: const AlarmSound.bundled(BundledAlarmSounds.chime)),
        base.copyWith(sound: const AlarmSound.bundled(BundledAlarmSounds.rising)),
        base.copyWith(
          sound: const AlarmSound.device(title: 'Oxygen', path: '/a.ogg'),
        ),
        base.copyWith(silentWhenRingerMuted: true),
        base.copyWith(label: '운동'),
        base.copyWith(label: ''),
      ];
      expect({for (final a in variants) sig(a)}, hasLength(variants.length));
    });

    test('웨이브 1 전 지문(vibrate 자리)과 겹치지 않는다 — 올린 뒤 이미 걸린 회차를 한 번 다시 건다', () {
      // 웨이브 1 전 signatureFor: 같은 자리에 alarm.vibrate 를 넣었다.
      String legacy(Alarm alarm, {required bool vibrate}) {
        final input = [
          'system',
          BundledAlarmSounds.beep,
          vibrate,
          alarm.label,
          0.8,
          3000,
          300,
        ].join('\u0000');
        var hash = 0x811c9dc5;
        for (final byte in utf8.encode(input)) {
          hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
        }
        return hash.toRadixString(16).padLeft(8, '0');
      }

      for (final vibrate in [false, true]) {
        for (final silent in [false, true]) {
          expect(
            sig(base.copyWith(silentWhenRingerMuted: silent)),
            isNot(legacy(base, vibrate: vibrate)),
            reason: 'vibrate=$vibrate · silentWhenRingerMuted=$silent',
          );
        }
      }
    });

    test('알림 아이콘을 넣기 전 지문과 겹치지 않는다 — 올린 뒤 이미 걸린 회차를 새 아이콘으로 다시 건다', () {
      // 66a2326 전 signatureFor: 알림 아이콘이 입력에 없었다. 그때 걸린 회차는 icon 이 null 이라
      // 포크가 적응형 런처 아이콘으로 알림을 만든다.
      String preIcon(Alarm alarm) {
        final input = [
          switch (alarm.sound) {
            SystemAlarmSound() => 'system',
            BundledAlarmSound(:final asset) => 'bundled:$asset',
            DeviceAlarmSound(:final path) => 'device:$path',
          },
          BundledAlarmSounds.beep,
          'silentWhenRingerMuted:${alarm.silentWhenRingerMuted}',
          alarm.label,
          0.8,
          3000,
          300,
        ].join('\u0000');
        var hash = 0x811c9dc5;
        for (final byte in utf8.encode(input)) {
          hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
        }
        return hash.toRadixString(16).padLeft(8, '0');
      }

      for (final alarm in [
        base,
        base.copyWith(label: '', silentWhenRingerMuted: true),
        base.copyWith(sound: const AlarmSound.bundled(BundledAlarmSounds.chime)),
      ]) {
        expect(sig(alarm), isNot(preIcon(alarm)), reason: '$alarm');
      }
    });

    test('볼륨 · 점점 커지기 · 스누즈 간격 · 한도 · 자동 멈춤이 바뀌면 지문이 바뀐다', () {
      final variants = [
        base,
        base.copyWith(volumePercent: 50),
        base.copyWith(fadeSeconds: 30),
        base.copyWith(fadeSeconds: 60),
        base.copyWith(snoozeMinutes: 10),
        base.copyWith(snoozeLimit: 3),
        base.copyWith(autoStopMinutes: 5),
        base.copyWith(autoStopMinutes: 15),
      ];
      expect({for (final a in variants) sig(a)}, hasLength(variants.length));
    });

    test('미리 알림 · 건너뛰기는 울림과 상관없어 지문에 들지 않는다', () {
      expect(sig(base.copyWith(remindBefore: true)), sig(base));
      expect(sig(base.copyWith(skippedAt: DateTime(2026, 10, 1, 7, 5))), sig(base));
    });

    test('웨이브 3 전 지문(고정 볼륨 0.8 · 페이드 3초 · 스누즈 5분)과 겹치지 않는다 — 올린 뒤 한 번 다시 건다', () {
      String preWave3(Alarm alarm) {
        final input = [
          'system',
          BundledAlarmSounds.beep,
          'silentWhenRingerMuted:${alarm.silentWhenRingerMuted}',
          alarm.label,
          0.8,
          3000,
          300,
          'icon:ic_stat_alarm',
        ].join('\u0000');
        var hash = 0x811c9dc5;
        for (final byte in utf8.encode(input)) {
          hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
        }
        return hash.toRadixString(16).padLeft(8, '0');
      }

      for (final alarm in [base, base.copyWith(label: ''), base.copyWith(silentWhenRingerMuted: true)]) {
        expect(sig(alarm), isNot(preWave3(alarm)), reason: '$alarm');
      }
    });

    test('울림과 상관없는 값(켜짐 · 시각)은 지문에 들지 않는다', () {
      expect(sig(base.copyWith(enabled: false)), sig(base));
      expect(sig(base.copyWith(hour: 9, minute: 30)), sig(base));
    });

    test('로캘 문구는 지문에 영향이 없다', () {
      String payload(AlarmNotificationTexts texts) =>
          PackageAlarmScheduler.settingsFor(312, at, base.copyWith(label: ''), texts).payload!;

      expect(
        payload((locale: 'en', defaultTitle: 'Alarm', stop: 'Stop', snooze: (_) => 'Snooze')),
        payload(texts),
      );
    });

    test('payload 에서 지문을 읽는다 — 옛 payload 는 빈 지문', () {
      final settings = PackageAlarmScheduler.settingsFor(312, at, base, texts);
      expect(PackageAlarmScheduler.ringOf(settings), (at: at, signature: sig(base)));
      expect(PackageAlarmScheduler.ringOf(settings.copyWith(payload: () => '3')), (
        at: at,
        signature: '',
      ));
      expect(PackageAlarmScheduler.ringOf(settings.copyWith(payload: () => null)), (
        at: at,
        signature: '',
      ));
    });
  });
}
