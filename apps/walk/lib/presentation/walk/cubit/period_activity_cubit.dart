import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/walk/entity/period_kind.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import 'period_activity_state.dart';

class PeriodActivityCubit extends Cubit<PeriodActivityState> {
  PeriodActivityCubit(this._useCase, this.kind)
    : super(const PeriodActivityState.loading(0));

  final WalkUseCase _useCase;
  final PeriodKind kind;
  int _generation = 0;

  int get _offset => switch (state) {
    PeriodActivityLoading(:final offset) ||
    PeriodActivityLoaded(:final offset) ||
    PeriodActivityFailure(:final offset) => offset,
  };

  Future<void> load() => _read(_offset, showLoading: true);

  Future<void> refresh() => _read(_offset, showLoading: false);

  Future<void> previous() => _read(_offset - 1, showLoading: true);

  /// 현재 기간(offset 0)보다 미래로는 가지 않는다.
  Future<void> next() {
    if (_offset >= 0) return Future.value();
    return _read(_offset + 1, showLoading: true);
  }

  Future<void> _read(int offset, {required bool showLoading}) async {
    final generation = ++_generation;
    if (showLoading) emit(PeriodActivityState.loading(offset));
    final result = await _useCase.period(kind, offset);
    if (isClosed || generation != _generation) return;
    emit(switch (result) {
      Ok(value: final period) => PeriodActivityState.loaded(offset, period),
      Err(:final failure) => PeriodActivityState.failure(offset, failure),
    });
  }
}
