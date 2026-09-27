import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecase/walk_use_case.dart';
import 'today_activity_state.dart';

class TodayActivityCubit extends Cubit<TodayActivityState> {
  TodayActivityCubit(this._useCase) : super(const TodayActivityState.loading());

  final WalkUseCase _useCase;
  int _generation = 0;

  Future<void> load() => _read(showLoading: true);

  /// 당겨서 새로고침 · 복귀 때. 이미 보이는 값을 로딩으로 지우지 않는다.
  Future<void> refresh() => _read(showLoading: false);

  Future<void> _read({required bool showLoading}) async {
    final generation = ++_generation;
    if (showLoading) emit(const TodayActivityState.loading());
    final result = await _useCase.today();
    if (isClosed || generation != _generation) return;
    emit(switch (result) {
      Ok(value: final activity) => TodayActivityState.loaded(activity),
      Err(:final failure) => TodayActivityState.failure(failure),
    });
  }
}
