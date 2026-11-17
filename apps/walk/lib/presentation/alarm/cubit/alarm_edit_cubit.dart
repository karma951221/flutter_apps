import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_pause.dart';
import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/entity/repeat_preset.dart';
import '../../../domain/alarm/holiday/holiday_calendar_access.dart';
import '../../../domain/alarm/one_shot_draft.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import 'alarm_edit_state.dart';
import 'alarm_save_result.dart';
import 'ensure_for_alarm_quietly.dart';

/// 종류(한 번 · 반복)는 [initial] 로 정해지고 편집 중에는 바뀌지 않는다 — 반복 알람의 요일을
/// 모두 꺼도 한 번 알람이 되지 않고 저장할 수 없을 뿐이다.
class AlarmEditCubit extends Cubit<AlarmEditState> {
  AlarmEditCubit(
    this._useCase,
    this._permissions,
    this._clock,
    Alarm initial, {
    required HolidayCalendarAccess holidayCalendar,
  }) : _holidayCalendar = holidayCalendar,
       _oneShot = initial.isOneShot,
       super(
         AlarmEditState(
           alarm: initial,
           draft: initial.isOneShot
               ? OneShotDraft.fromAlarm(initial, _clock.now())
               : const OneShotDraft(),
         ),
       );

  final AlarmUseCase _useCase;
  final AlarmPermissions _permissions;
  final Clock _clock;

  /// 반복 알람을 저장한 뒤 공휴일 미리 알림용 캘린더 권한을 묻는다(켜져 있을 때만).
  final HolidayCalendarAccess _holidayCalendar;
  final bool _oneShot;

  /// 한 번 알람이면 울릴 시각이 1분 이상 남았을 때, 반복 알람이면 요일이 하나라도 있을 때.
  bool canSave(DateTime now) =>
      _oneShot ? state.draft.canSave(now) : state.alarm.repeat.isNotEmpty;

  void addOffset(Duration step) => _updateDraft(state.draft.add(step));

  void resetOffset() => _updateDraft(state.draft.reset());

  void fixOneShotAt(int hour, int minute) =>
      _updateDraft(state.draft.fixAt(hour, minute, _clock.now()));

  void applyPreset(RepeatPreset preset) =>
      _update(state.alarm.copyWith(repeat: preset.days));

  /// 예전 1회성 울릴 시각은 버린다 — save 가 새 시각의 다음 회차로 정한다.
  void setTime(int hour, int minute) => _update(
    state.alarm.copyWith(hour: hour, minute: minute, oneShotAt: null),
  );

  void toggleDay(Weekday day) {
    final repeat = {...state.alarm.repeat};
    if (!repeat.remove(day)) repeat.add(day);
    _update(state.alarm.copyWith(repeat: repeat));
  }

  void setLabel(String label) =>
      _update(state.alarm.copyWith(label: label.trim()));

  void setSilentWhenRingerMuted(bool value) =>
      _update(state.alarm.copyWith(silentWhenRingerMuted: value));

  void setSound(AlarmSound sound) =>
      _update(state.alarm.copyWith(sound: sound));

  // 울림 설정. 값은 화면이 `AlarmOptions` 의 선택지에서 고른다.

  void setVolumePercent(int percent) =>
      _update(state.alarm.copyWith(volumePercent: percent));

  void setFadeSeconds(int seconds) =>
      _update(state.alarm.copyWith(fadeSeconds: seconds));

  void setSnoozeMinutes(int minutes) =>
      _update(state.alarm.copyWith(snoozeMinutes: minutes));

  /// null 이면 무제한.
  void setSnoozeLimit(int? limit) =>
      _update(state.alarm.copyWith(snoozeLimit: limit));

  /// null 이면 자동 멈춤 안 함.
  void setAutoStopMinutes(int? minutes) =>
      _update(state.alarm.copyWith(autoStopMinutes: minutes));

  void setRemindBefore(bool value) =>
      _update(state.alarm.copyWith(remindBefore: value));

  /// 켠 상태로 저장하고(예약까지) 권한을 확인한다 — 거부되거나 확인이 실패해도 저장은
  /// 이미 끝났다(목록 경고 배너가 남은 길). 반복 알람이면 공휴일 미리 알림용 캘린더 권한도
  /// 묻는다(거부하면 내장 표). 울릴 때까지 남은 시간을 돌려준다 — 쉬는 기간의 회차는 빼고
  /// 센다(기간을 못 읽으면 쉬지 않는 것으로).
  /// 쉬는 기간 때문에 울릴 회차가 없으면 그렇다고 돌려준다([AlarmSaveResult.of]).
  /// 저장이 실패하면 던진다.
  Future<AlarmSaveResult?> save() => _busy(() async {
    final now = _clock.now();
    if (!canSave(now)) throw StateError('alarm cannot be saved yet');
    final ringAt = state.draft.ringAt(now);
    final alarm = _oneShot
        ? state.alarm.copyWith(
            hour: ringAt.hour,
            minute: ringAt.minute,
            oneShotAt: ringAt,
          )
        : state.alarm;
    final saved = await _useCase.save(alarm);
    await ensureForAlarmQuietly(_permissions);
    if (!saved.isOneShot) {
      try {
        await _holidayCalendar.ensureIfReminding();
      } on Object {
        // 저장은 끝났다 — 캘린더를 못 읽으면 내장 표로 판정한다.
      }
    }
    AlarmPause? pause;
    try {
      pause = await _useCase.pause();
    } on Object {
      // 저장은 끝났다 — 쉬지 않는 것으로 센다.
    }
    return AlarmSaveResult.of(saved, _clock.now(), pause);
  });

  Future<void> delete() => _busy(() => _useCase.delete(state.alarm.id));

  Future<T> _busy<T>(Future<T> Function() body) async {
    emit(state.copyWith(busy: true));
    try {
      return await body();
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  void _update(Alarm alarm) {
    if (state.busy) return;
    emit(state.copyWith(alarm: alarm));
  }

  void _updateDraft(OneShotDraft draft) {
    if (state.busy) return;
    emit(state.copyWith(draft: draft));
  }
}
