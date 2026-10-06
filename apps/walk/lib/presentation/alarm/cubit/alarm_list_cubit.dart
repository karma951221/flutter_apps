import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/holiday/holiday_calendar.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/reminders.dart';
import '../../../domain/alarm/upcoming_triggers.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import 'alarm_list_state.dart';
import 'ensure_for_alarm_quietly.dart';

/// 알람 탭. 셸이 소유한다 — 시작 · 복귀(sync 뒤) · 위에 얹힌 화면이 걷힐 때 [load].
/// 화면이 떠 있는 동안에는 매분 0초에 [tick] 해 남은 시간을 새로 센다.
class AlarmListCubit extends Cubit<AlarmListState> {
  AlarmListCubit(this._useCase, this._permissions, this._clock, this._holidays)
    : super(const AlarmListState.loading());

  final AlarmUseCase _useCase;
  final AlarmPermissions _permissions;
  final Clock _clock;

  /// "공휴일" 칩 판정. 동기 — 폰 캘린더 캐시나 내장 표를 읽는다.
  final HolidayCalendar _holidays;

  /// 던지지 않는다. 목록을 못 읽으면 failure, 다음 울림을 못 읽으면 `nextAt` 을 비우고,
  /// 권한을 확인하지 못하면 울릴지 모르니 경고(`canRing: false`)로 둔다.
  Future<void> load() async {
    final List<Alarm> alarms;
    try {
      alarms = await _useCase.list();
    } on Object {
      if (!isClosed) emit(const AlarmListState.failure());
      return;
    }
    final nextAt = await _orElse(_useCase.nextRings, const <int, DateTime>{});
    final canRing = await _orElse(_permissions.canRing, false);
    if (isClosed) return;
    final now = _clock.now();
    emit(AlarmListState.loaded(
      alarms: alarms,
      nextAt: nextAt,
      now: now,
      canRing: canRing,
      holidays: _holidaysOf(alarms, now),
    ));
  }

  /// 규칙의 다음 회차가 [alarmHolidayLead](공휴일 미리 알림과 같은 24시간) 안이고 그날이 공휴일인
  /// 반복 알람 id → 공휴일 이름. 칩을 누르면 그 회차를 건너뛰는(건너뛰었으면 취소하는) 시트가 뜬다.
  /// 회차는 `skipNext` 가 고르는 것과 같게 건너뛰기를 빼고 센다. 걸린 예약(`nextAt`)은 보지 않는다 —
  /// 스누즈된 울림은 건너뛰기 대상이 아니라, 그것으로 정하면 칩과 다른 날을 건너뛴다.
  Map<int, String> _holidaysOf(List<Alarm> alarms, DateTime now) {
    final names = <int, String>{};
    for (final alarm in alarms) {
      if (alarm.isOneShot) continue;
      final at = upcomingTriggers(alarm.copyWith(skippedAt: null), now).firstOrNull;
      if (at == null || at.difference(now) > alarmHolidayLead) continue;
      if (_holidays.nameOf(at) case final name?) names[alarm.id] = name;
    }
    return names;
  }

  static Future<T> _orElse<T>(Future<T> Function() read, T fallback) async {
    try {
      return await read();
    } on Object {
      return fallback;
    }
  }

  /// 표시 기준 시각만 옮긴다 — 저장소 · 예약은 읽지 않는다. 어떤 알람의 울릴 시각이
  /// 지났으면 대신 [load] 해 다음 회차로 넘긴다.
  Future<void> tick() async {
    if (state case AlarmListLoaded(:final nextAt) && final loaded) {
      final now = _clock.now();
      if (nextAt.values.any((at) => !now.isBefore(at))) return load();
      emit(loaded.copyWith(now: now, holidays: _holidaysOf(loaded.alarms, now)));
    }
  }

  /// 반복 알람의 다음 회차 하나를 건너뛴다(길게 누르기 · 공휴일 칩 시트). 실패하면 다시 읽은 뒤 던진다.
  Future<void> skipNext(int alarmId) => _thenLoad(() => _useCase.skipNext(alarmId));

  /// 건너뛰기를 취소한다. 실패하면 다시 읽은 뒤 던진다.
  Future<void> unskip(int alarmId) => _thenLoad(() => _useCase.unskip(alarmId));

  Future<void> _thenLoad(Future<void> Function() change) async {
    try {
      await change();
    } finally {
      await load();
    }
  }

  /// 스위치. 스위치가 바로 움직이게 먼저 반영하고 저장한다. 켰으면 권한을 확인하고
  /// 울릴 때까지 남은 시간을 돌려준다(스낵바). 끄거나 실패하면 null.
  Future<Duration?> toggle(Alarm alarm, {required bool enabled}) async {
    if (state case AlarmListLoaded(:final alarms) && final loaded) {
      emit(loaded.copyWith(alarms: [
        for (final a in alarms) a.id == alarm.id ? a.copyWith(enabled: enabled) : a,
      ]));
    }
    try {
      final toggled = await _useCase.toggle(alarm.id, enabled: enabled);
      if (!enabled || toggled == null) return null;
      await ensureForAlarmQuietly(_permissions);
      final triggers = upcomingTriggers(toggled, _clock.now());
      return triggers.isEmpty ? null : triggers.first.difference(_clock.now());
    } finally {
      await load();
    }
  }
}
