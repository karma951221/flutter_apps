import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/alarm/usecase/alarm_use_case.dart';
import 'alarm_ringing_state.dart';

/// 울림 화면 하나 = 울리는 회차(패키지 id) 하나.
class AlarmRingingCubit extends Cubit<AlarmRingingState> {
  AlarmRingingCubit(this._useCase, this.packageId)
    : super(const AlarmRingingState());

  final AlarmUseCase _useCase;
  final int packageId;

  Future<void> load() async {
    final alarm = await _useCase.findByPackageId(packageId);
    bool canSnooze;
    try {
      canSnooze = await _useCase.canSnooze(packageId);
    } on Object {
      canSnooze = true;
    }
    if (!isClosed) emit(state.copyWith(alarm: alarm, canSnooze: canSnooze));
  }

  Future<void> snooze() => _busy(() => _useCase.snooze(packageId));

  Future<void> stop() => _busy(() => _useCase.stop(packageId));

  Future<void> _busy(Future<void> Function() body) async {
    emit(state.copyWith(busy: true));
    try {
      await body();
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }
}
