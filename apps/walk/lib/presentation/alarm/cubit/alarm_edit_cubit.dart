import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/upcoming_triggers.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import 'alarm_edit_state.dart';
import 'ensure_for_alarm_quietly.dart';

class AlarmEditCubit extends Cubit<AlarmEditState> {
  AlarmEditCubit(this._useCase, this._permissions, this._clock, Alarm initial)
    : super(AlarmEditState(alarm: initial));

  final AlarmUseCase _useCase;
  final AlarmPermissions _permissions;
  final Clock _clock;

  void setTime(int hour, int minute) =>
      _update(state.alarm.copyWith(hour: hour, minute: minute));

  void toggleDay(Weekday day) {
    final repeat = {...state.alarm.repeat};
    if (!repeat.remove(day)) repeat.add(day);
    _update(state.alarm.copyWith(repeat: repeat));
  }

  void setLabel(String label) => _update(state.alarm.copyWith(label: label.trim()));

  void setVibrate(bool vibrate) => _update(state.alarm.copyWith(vibrate: vibrate));

  void setSound(AlarmSound sound) => _update(state.alarm.copyWith(sound: sound));

  /// 켠 상태로 저장하고(예약까지) 권한을 확인한다 — 거부되거나 확인이 실패해도 저장은
  /// 이미 끝났다(목록 경고 배너가 남은 길). 울릴 때까지 남은 시간을 돌려준다.
  /// 저장이 실패하면 던진다.
  Future<Duration?> save() => _busy(() async {
    final saved = await _useCase.save(state.alarm);
    await ensureForAlarmQuietly(_permissions);
    final now = _clock.now();
    final triggers = upcomingTriggers(saved, now);
    return triggers.isEmpty ? null : triggers.first.difference(now);
  });

  Future<void> delete() => _busy(() => _useCase.delete(state.alarm.id));

  Future<T> _busy<T>(Future<T> Function() body) async {
    emit(AlarmEditState(alarm: state.alarm, busy: true));
    try {
      return await body();
    } finally {
      if (!isClosed) emit(AlarmEditState(alarm: state.alarm));
    }
  }

  void _update(Alarm alarm) {
    if (state.busy) return;
    emit(AlarmEditState(alarm: alarm));
  }
}
