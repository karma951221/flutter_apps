import 'package:freezed_annotation/freezed_annotation.dart';

part 'alarm_sound.freezed.dart';

/// 알람이 울릴 소리.
@freezed
sealed class AlarmSound with _$AlarmSound {
  const AlarmSound._();

  /// 기기의 기본 알람음.
  const factory AlarmSound.system() = SystemAlarmSound;

  /// 앱 에셋. [asset] 은 `assets/alarm/…`([BundledAlarmSounds]).
  const factory AlarmSound.bundled(String asset) = BundledAlarmSound;

  /// 기기 알람음을 앱 저장소로 복사한 것. [title] 은 기기 목록의 이름, [path] 는 복사본의 절대 경로.
  const factory AlarmSound.device({
    required String title,
    required String path,
  }) = DeviceAlarmSound;

  /// 사용자가 고른 오디오 파일. [title] 은 파일 이름에서 뺀 표시 이름, [path] 는 앱 저장소로 복사한 복사본의 절대 경로.
  const factory AlarmSound.file({required String title, required String path}) =
      FileAlarmSound;

  Map<String, Object?> toJson() => switch (this) {
    SystemAlarmSound() => const {'type': 'system'},
    BundledAlarmSound(:final asset) => {'type': 'bundled', 'asset': asset},
    DeviceAlarmSound(:final title, :final path) => {
      'type': 'device',
      'title': title,
      'path': path,
    },
    FileAlarmSound(:final title, :final path) => {
      'type': 'file',
      'title': title,
      'path': path,
    },
  };

  /// 절대 던지지 않는다 — 값이 없거나 형식을 모르면 [AlarmSound.system].
  /// (Freezed 가 factory 를 union 으로 오해하지 않게 static 으로 둔다.)
  static AlarmSound fromJson(Object? json) => switch (json) {
    {'type': 'bundled', 'asset': final String asset} => AlarmSound.bundled(
      _migrated(asset),
    ),
    {
      'type': 'device',
      'title': final String title,
      'path': final String path,
    } =>
      AlarmSound.device(title: title, path: path),
    {'type': 'file', 'title': final String title, 'path': final String path} =>
      AlarmSound.file(title: title, path: path),
    _ => const AlarmSound.system(),
  };

  /// 목록에서 뺀 옛 에셋은 가장 비슷한 새 소리로 옮긴다(이미 걸린 회차는 옛 파일로 그대로 울린다).
  static String _migrated(String asset) => switch (asset) {
    BundledAlarmSounds.legacyChime => BundledAlarmSounds.morning,
    BundledAlarmSounds.legacyRising => BundledAlarmSounds.classic,
    _ => asset,
  };
}

/// 앱에 들어 있는 알람음 에셋. 표시 이름은 presentation 이 경로로 고른다.
/// ogg 4개는 `tool/alarm_sounds/generate.py` 로 직접 합성했다(assets/alarm/README.md).
abstract final class BundledAlarmSounds {
  /// 아침 차임 — 장3화음을 위로 오르는 맑은 벨. 새 알람의 기본.
  static const morning = 'assets/alarm/morning.ogg';

  /// 마림바 — 나무 음색의 짧고 밝은 멜로디.
  static const marimba = 'assets/alarm/marimba.ogg';

  /// 클래식 벨 — 탁상 자명종처럼 빠르게 두드리는 금속 벨.
  static const classic = 'assets/alarm/classic.ogg';

  /// 새소리 — 주파수가 휘는 짧은 지저귐.
  static const birds = 'assets/alarm/birds.ogg';

  /// 기존 비프. 이미 걸린 회차가 이 경로로 울리므로 이름을 바꾸지 않는다.
  static const beep = 'assets/alarm/default.wav';

  /// 옛 2음 차임. 목록에서는 뺐지만 이미 걸린 회차가 이 경로로 울리므로 파일은 남긴다.
  static const legacyChime = 'assets/alarm/chime.wav';

  /// 옛 점점 빨라지는 비프. [legacyChime] 과 같은 이유로 파일만 남긴다.
  static const legacyRising = 'assets/alarm/rising.wav';

  static const all = [morning, marimba, classic, birds, beep];
}
