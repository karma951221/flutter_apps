import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm_sound.dart';

/// 알람음 이름 — 편집 화면의 알람음 줄 · 선택 화면의 줄.
abstract final class AlarmSoundFormat {
  static String name(AppLocalizations l10n, AlarmSound sound) =>
      switch (sound) {
        SystemAlarmSound() => l10n.walkAlarmSoundSystem,
        BundledAlarmSound(:final asset) => bundled(l10n, asset),
        DeviceAlarmSound(:final title) => title,
      };

  /// 내장음 이름. 모르는 에셋이면 확장자를 뺀 파일 이름.
  static String bundled(AppLocalizations l10n, String asset) => switch (asset) {
    BundledAlarmSounds.beep => l10n.walkAlarmSoundBeep,
    BundledAlarmSounds.chime => l10n.walkAlarmSoundChime,
    BundledAlarmSounds.rising => l10n.walkAlarmSoundRising,
    _ => asset.split('/').last.split('.').first,
  };
}
