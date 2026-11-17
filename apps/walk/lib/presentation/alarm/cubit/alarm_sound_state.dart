import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/sound/alarm_sound_source.dart';

part 'alarm_sound_state.freezed.dart';

/// 알람음 선택 화면에서 선택 표시가 붙은 항목.
@freezed
sealed class AlarmSoundChoice with _$AlarmSoundChoice {
  const factory AlarmSoundChoice.system() = SystemSoundChoice;

  const factory AlarmSoundChoice.bundled(String asset) = BundledSoundChoice;

  /// 기기 알람음 목록의 한 줄 — 고르면(선택 버튼) 앱 저장소로 복사한다.
  const factory AlarmSoundChoice.device(DeviceRingtone ringtone) =
      DeviceSoundChoice;

  /// 내 파일 구역의 줄 — 이미 앱 저장소로 복사해 둔 파일이라 그대로 선택하면 이 값을 돌려준다.
  const factory AlarmSoundChoice.file(FileAlarmSound sound) = FileSoundChoice;

  /// 이미 복사해 둔 기기 소리인데 목록에서 같은 제목을 찾지 못했다(원본 삭제 등).
  /// 어느 줄에도 표시하지 않고, 그대로 선택하면 이 값을 돌려준다.
  const factory AlarmSoundChoice.current(AlarmSound sound) = CurrentSoundChoice;
}

/// 기기 알람음 목록.
@freezed
sealed class DeviceRingtones with _$DeviceRingtones {
  const factory DeviceRingtones.loading() = DeviceRingtonesLoading;

  const factory DeviceRingtones.loaded(List<DeviceRingtone> items) =
      DeviceRingtonesLoaded;

  const factory DeviceRingtones.failure() = DeviceRingtonesFailure;
}

@freezed
class AlarmSoundState with _$AlarmSoundState {
  @override
  final AlarmSoundChoice selected;

  @override
  final DeviceRingtones ringtones;

  /// 기기 알람음 · 고른 파일을 복사하는 중 — 선택 버튼 로딩, 다른 줄 선택을 막는다.
  @override
  final bool importing;

  /// 내 파일 구역에 보일 파일. 현재 소리가 파일이거나 이 화면에서 새로 고른 것 — 늘 [FileAlarmSound].
  /// (타입을 [AlarmSound] 로 두는 것은 Freezed 가 다른 라이브러리의 생성 타입을 copyWith 에서
  /// 못 읽기 때문이다.)
  @override
  final AlarmSound? myFile;

  const AlarmSoundState({
    required this.selected,
    this.ringtones = const DeviceRingtones.loading(),
    this.importing = false,
    this.myFile,
  });
}
