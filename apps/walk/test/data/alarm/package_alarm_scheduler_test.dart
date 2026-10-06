import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/data/alarm/package_alarm_scheduler.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
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
    expect(settings.volumeSettings.fadeDuration, const Duration(seconds: 3));
    expect(settings.volumeSettings.showSystemUI, isFalse);
    expect(settings.androidFullScreenIntent, isTrue);
    expect(settings.androidStopAlarmOnTermination, isFalse);
    expect(settings.androidSnoozeDuration, alarmSnoozeDuration);
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
          alarmSnoozeDuration.inSeconds,
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

    test('울림과 상관없는 값(켜짐 · 시각)은 지문에 들지 않는다', () {
      expect(sig(base.copyWith(enabled: false)), sig(base));
      expect(sig(base.copyWith(hour: 9, minute: 30)), sig(base));
    });

    test('로캘 문구는 지문에 영향이 없다', () {
      String payload(AlarmNotificationTexts texts) =>
          PackageAlarmScheduler.settingsFor(312, at, base.copyWith(label: ''), texts).payload!;

      expect(
        payload((locale: 'en', defaultTitle: 'Alarm', stop: 'Stop', snooze: 'Snooze')),
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
