import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/sound/alarm_sound_source.dart';
import 'alarm_sound_state.dart';

/// 알람음 선택 화면. 줄을 고르면 미리 듣고, [confirm] 으로 결과 소리를 만든다.
/// 닫으면 미리 듣기를 멈춘다.
class AlarmSoundCubit extends Cubit<AlarmSoundState> {
  AlarmSoundCubit(this._source, AlarmSound initial)
    : super(AlarmSoundState(selected: _choiceOf(initial)));

  final AlarmSoundSource _source;

  static AlarmSoundChoice _choiceOf(AlarmSound sound) => switch (sound) {
    SystemAlarmSound() => const AlarmSoundChoice.system(),
    BundledAlarmSound(:final asset) => AlarmSoundChoice.bundled(asset),
    DeviceAlarmSound() => AlarmSoundChoice.current(sound),
  };

  /// 기기 알람음 목록을 읽는다. 현재 소리가 복사해 둔 기기 소리면 같은 제목의 줄에 표시를 옮긴다.
  Future<void> load() async {
    final DeviceRingtones ringtones;
    try {
      ringtones = DeviceRingtones.loaded(await _source.deviceRingtones());
    } on Object {
      if (!isClosed) emit(state.copyWith(ringtones: const DeviceRingtones.failure()));
      return;
    }
    if (isClosed) return;
    var selected = state.selected;
    if ((selected, ringtones) case (
      CurrentSoundChoice(sound: DeviceAlarmSound(:final title)),
      DeviceRingtonesLoaded(:final items),
    )) {
      for (final item in items) {
        if (item.title == title) {
          selected = AlarmSoundChoice.device(item);
          break;
        }
      }
    }
    emit(state.copyWith(selected: selected, ringtones: ringtones));
  }

  /// 선택 표시를 옮기고 미리 듣는다. 미리 듣기 실패는 무시한다.
  Future<void> select(AlarmSoundChoice choice) async {
    if (state.importing) return;
    emit(state.copyWith(selected: choice));
    try {
      await switch (choice) {
        SystemSoundChoice() => _source.preview(const AlarmSound.system()),
        BundledSoundChoice(:final asset) => _source.preview(AlarmSound.bundled(asset)),
        DeviceSoundChoice(:final ringtone) => _source.preview(
          const AlarmSound.system(),
          uri: ringtone.uri,
        ),
        CurrentSoundChoice(:final sound) => _source.preview(sound),
      };
    } on Object {
      // 미리 듣기는 보조 기능이라 실패해도 고르기는 계속된다.
    }
  }

  /// 고른 소리. 기기 알람음이면 앱 저장소로 복사한 결과이고, 복사가 실패하면 던진다.
  Future<AlarmSound> confirm() async {
    switch (state.selected) {
      case SystemSoundChoice():
        return const AlarmSound.system();
      case BundledSoundChoice(:final asset):
        return AlarmSound.bundled(asset);
      case CurrentSoundChoice(:final sound):
        return sound;
      case DeviceSoundChoice(:final ringtone):
        emit(state.copyWith(importing: true));
        try {
          return await _source.import(ringtone);
        } finally {
          if (!isClosed) emit(state.copyWith(importing: false));
        }
    }
  }

  @override
  Future<void> close() async {
    await _source.stopPreview();
    return super.close();
  }
}
