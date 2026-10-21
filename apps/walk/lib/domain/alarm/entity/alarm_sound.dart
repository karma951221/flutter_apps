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

  Map<String, Object?> toJson() => switch (this) {
    SystemAlarmSound() => const {'type': 'system'},
    BundledAlarmSound(:final asset) => {'type': 'bundled', 'asset': asset},
    DeviceAlarmSound(:final title, :final path) => {
      'type': 'device',
      'title': title,
      'path': path,
    },
  };

  /// 절대 던지지 않는다 — 값이 없거나 형식을 모르면 [AlarmSound.system].
  /// (Freezed 가 factory 를 union 으로 오해하지 않게 static 으로 둔다.)
  static AlarmSound fromJson(Object? json) => switch (json) {
    {'type': 'bundled', 'asset': final String asset} => AlarmSound.bundled(
      asset,
    ),
    {
      'type': 'device',
      'title': final String title,
      'path': final String path,
    } =>
      AlarmSound.device(title: title, path: path),
    _ => const AlarmSound.system(),
  };
}

/// 앱에 들어 있는 알람음 에셋. 표시 이름은 presentation 이 경로로 고른다.
abstract final class BundledAlarmSounds {
  /// 기존 비프. 이미 걸린 회차가 이 경로로 울리므로 이름을 바꾸지 않는다.
  static const beep = 'assets/alarm/default.wav';

  /// 부드러운 2음 차임.
  static const chime = 'assets/alarm/chime.wav';

  /// 간격이 점점 짧아지는 비프.
  static const rising = 'assets/alarm/rising.wav';

  static const all = [beep, chime, rising];
}
