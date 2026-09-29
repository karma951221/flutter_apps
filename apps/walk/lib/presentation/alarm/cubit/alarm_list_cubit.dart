import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/upcoming_triggers.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../../../domain/clock.dart';
import 'alarm_list_state.dart';
import 'ensure_for_alarm_quietly.dart';

/// 알람 탭. 셸이 소유한다 — 시작 · 복귀(sync 뒤) · 위에 얹힌 화면이 걷힐 때 [load].
/// 화면이 떠 있는 동안에는 매분 0초에 [tick] 해 남은 시간을 새로 센다.
class AlarmListCubit extends Cubit<AlarmListState> {
  AlarmListCubit(this._useCase, this._permissions, this._clock)
    : super(const AlarmListState.loading());

  final AlarmUseCase _useCase;
  final AlarmPermissions _permissions;
  final Clock _clock;

  Future<void> load() async {
    final alarms = await _useCase.list();
    final nextAt = await _useCase.nextRings();
    final canRing = await _permissions.canRing();
    if (isClosed) return;
    emit(AlarmListState.loaded(
      alarms: alarms,
      nextAt: nextAt,
      now: _clock.now(),
      canRing: canRing,
    ));
  }

  /// 표시 기준 시각만 옮긴다 — 저장소 · 예약은 읽지 않는다. 어떤 알람의 울릴 시각이
  /// 지났으면 대신 [load] 해 다음 회차로 넘긴다.
  Future<void> tick() async {
    if (state case AlarmListLoaded(:final nextAt) && final loaded) {
      final now = _clock.now();
      if (nextAt.values.any((at) => !now.isBefore(at))) return load();
      emit(loaded.copyWith(now: now));
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
