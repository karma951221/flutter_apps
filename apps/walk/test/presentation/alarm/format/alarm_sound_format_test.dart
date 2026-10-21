import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/presentation/alarm/format/alarm_sound_format.dart';

void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('시스템 기본', () {
    expect(AlarmSoundFormat.name(ko, const AlarmSound.system()), '시스템 기본');
    expect(AlarmSoundFormat.name(en, const AlarmSound.system()), 'System default');
  });

  test('내장음은 에셋 경로로 이름을 고른다 — default.wav 는 "비프"', () {
    expect(AlarmSoundFormat.name(ko, const AlarmSound.bundled(BundledAlarmSounds.beep)), '비프');
    expect(AlarmSoundFormat.name(ko, const AlarmSound.bundled(BundledAlarmSounds.chime)), '차임');
    expect(
      AlarmSoundFormat.name(ko, const AlarmSound.bundled(BundledAlarmSounds.rising)),
      '점점 빠르게',
    );
    expect(AlarmSoundFormat.bundled(en, BundledAlarmSounds.chime), 'Chime');
  });

  test('모르는 에셋은 파일 이름', () {
    expect(AlarmSoundFormat.bundled(ko, 'assets/alarm/new_tone.wav'), 'new_tone');
  });

  test('기기 알람음은 제목', () {
    expect(
      AlarmSoundFormat.name(ko, const AlarmSound.device(title: 'Bell', path: '/a.ogg')),
      'Bell',
    );
  });
}
