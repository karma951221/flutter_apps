import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/stats/entity/stats_period.dart';
import '../../../domain/stats/policy/walk_stats_policy.dart';
import '../../../domain/walk/entity/walk.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import 'stats_state.dart';

/// 통계 화면. 산책 스트림이 바뀌거나 기간을 옮길 때마다 [Clock] 의 지금으로 다시 계산한다 —
/// 화면을 연 채 자정을 넘기면 다음 갱신에서 새 날짜가 된다.
@injectable
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._useCase, this._clock) : super(const StatsState.loading());

  final WalkUseCase _useCase;
  final Clock _clock;

  StreamSubscription<Result<List<Walk>>>? _subscription;
  List<Walk>? _walks;
  StatsPeriod _period = StatsPeriod.week;
  int _offset = 0;

  Future<void> start() => _watch();

  Future<void> retry() => _watch();

  /// 기간 종류를 바꾸면 지금 기간으로 돌아온다.
  void selectPeriod(StatsPeriod period) {
    if (state is! StatsLoaded || period == _period) return;
    _period = period;
    _offset = 0;
    _emitLoaded();
  }

  void showPrevious() {
    if (state is! StatsLoaded) return;
    _offset--;
    _emitLoaded();
  }

  void showNext() {
    if (state is! StatsLoaded) return;
    _offset++;
    _emitLoaded();
  }

  Future<void> _watch() async {
    // 위젯 테스트의 가짜 비동기에서 끝난 스트림의 cancel 을 기다리면 멈추므로 기다리지 않는다.
    unawaited(_subscription?.cancel());
    if (isClosed) return;

    _walks = null;
    emit(const StatsState.loading());
    _subscription = _useCase.watchWalks().listen(_onWalks);
  }

  void _onWalks(Result<List<Walk>> result) {
    if (isClosed) return;
    switch (result) {
      case Ok(value: final walks):
        _walks = walks;
        _emitLoaded();
      case Err(:final failure):
        _walks = null;
        emit(StatsState.failure(failure));
    }
  }

  void _emitLoaded() {
    final walks = _walks;
    if (walks == null || isClosed) return;
    final now = _clock.now();
    final earliest = WalkStatsPolicy.earliestOffset(walks, _period, now);
    // 미래로는 가지 않고, 삭제로 오래된 산책이 사라지면 남은 가장 오래된 기간으로 끌어올린다.
    _offset = math.max(earliest, math.min(0, _offset));
    emit(
      StatsState.loaded(
        stats: WalkStatsPolicy.periodStats(
          walks,
          _period,
          now,
          offset: _offset,
        ),
        records: WalkStatsPolicy.records(walks, now),
        offset: _offset,
        canShowPrevious: _offset > earliest,
        canShowNext: _offset < 0,
        isEmpty: walks.isEmpty,
        now: now,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
