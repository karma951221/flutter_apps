import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/alarm/entity/alarm_trigger.dart';
import '../../../domain/alarm/entity/ring_log_entry.dart';
import '../../../domain/alarm/ring_log.dart';
import '../../../domain/alarm/ring_log/ring_log_source.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import 'alarm_history_state.dart';

/// 울림 기록 화면. 최근 [days] 일의 기록을 회차로 묶는다.
class AlarmHistoryCubit extends Cubit<AlarmHistoryState> {
  AlarmHistoryCubit(this._ringLog, this._useCase, this._clock)
    : super(const AlarmHistoryState.loading());

  final RingLogSource _ringLog;
  final AlarmUseCase _useCase;
  final Clock _clock;

  static const days = 30;

  Future<void> load() async {
    if (state is AlarmHistoryFailure) emit(const AlarmHistoryState.loading());
    final now = _clock.now();
    try {
      final entries = await _ringLog.read(
        since: DateTime(now.year, now.month, now.day - days),
      );
      final alarms = await _useCase.list();
      // 건너뛰기는 회차 시각으로 남는다(예전 기록엔 미리 건너뛴 앞날 회차도 있다) — 지난 일만 보인다.
      // 반복 알람의 건너뛰기는 회차가 지난 뒤 sync 가 기록하므로, 아직 sync 전이면 알람의
      // 지난 skippedAt 으로 채운다(기록과 겹쳐도 같은 회차라 한 줄이다).
      final past = [
        for (final e in entries)
          if (!e.at.isAfter(now)) e,
        for (final a in alarms)
          if (a.skippedAt case final at? when !at.isAfter(now))
            RingLogEntry(
              at: at,
              packageId: packageId(a.id, triggerIndex(at)),
              kind: RingLogKind.skipped,
            ),
      ];
      if (!isClosed) {
        emit(
          AlarmHistoryState.loaded(
            groups: ringLogGroups(past, alarms),
            now: now,
          ),
        );
      }
    } on Object {
      if (!isClosed) emit(const AlarmHistoryState.failure());
    }
  }
}
