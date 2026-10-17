import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/backup/entity/backup_import_result.dart';
import '../../../domain/stats/entity/period_summary.dart';
import '../../../domain/stats/entity/stats_period.dart';
import '../../../domain/stats/policy/walk_stats_policy.dart';
import '../../../domain/tracking/entity/tracker_state.dart';
import '../../../domain/walk/entity/walk.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import 'walk_feed_state.dart';

@injectable
class WalkFeedCubit extends Cubit<WalkFeedState> {
  WalkFeedCubit(this._useCase, this._clock)
    : super(const WalkFeedState.loading());

  final WalkUseCase _useCase;
  final Clock _clock;

  StreamSubscription<Result<List<Walk>>>? _walksSubscription;
  StreamSubscription<TrackerState>? _trackerSubscription;
  List<Walk>? _walks;
  TrackerState _tracker = const TrackerState.idle();
  PeriodSummary _weekSummary = PeriodSummary.empty;

  /// 내보내기 · 가져오기가 진행 중이면 다시 누른 것은 무시한다 — 공유 시트 · 파일 고르기가
  /// 두 번 뜨지 않게.
  bool _backupBusy = false;

  /// 추적기 상태를 먼저 읽고 두 스트림을 구독한다.
  Future<void> start() async {
    await _trackerSubscription?.cancel();
    if (isClosed) return;

    // 구독을 먼저 건다 — `trackerStates` 는 현재값을 내지 않으므로 놓치지 않게.
    _trackerSubscription = _useCase.trackerStates.listen(_onTracker);
    _tracker = _useCase.trackerState;
    await _watchWalks();
  }

  /// 실패 뒤 다시 읽는다. 추적 구독은 그대로 두고 산책 구독만 다시 건다.
  Future<void> retry() => _watchWalks();

  File photoFile(String relativePath) => _useCase.photoFile(relativePath);

  /// 모든 기록을 백업 파일로 공유한다. 진행 중에 다시 부르면 아무것도 하지 않고 성공으로 친다.
  Future<Result<void>> exportBackup() async {
    if (_backupBusy) return const Ok(null);
    _backupBusy = true;
    try {
      return await _useCase.exportBackup();
    } finally {
      _backupBusy = false;
    }
  }

  /// 백업을 골라 합친다. 상태는 바꾸지 않는다 — 가져온 산책은 스트림으로 들어온다.
  /// 진행 중에 다시 부르면 취소로 친다(알릴 것이 없다).
  Future<BackupImportResult> importBackup() async {
    if (_backupBusy) return const BackupImportResult.cancelled();
    _backupBusy = true;
    try {
      return await _useCase.importBackup();
    } finally {
      _backupBusy = false;
    }
  }

  /// 캐시한 목록으로 이번 주 요약을 지금 시각 기준으로 다시 잡는다 — 앱이 주 경계를
  /// 넘긴 채 백그라운드에 있다 돌아오면 스트림 값이 없어도 요약이 바뀌어야 한다.
  /// 목록이 아직 없거나 loaded 가 아니면 아무것도 하지 않는다.
  void refreshWeekSummary() {
    final walks = _walks;
    if (isClosed || walks == null || state is! WalkFeedLoaded) return;
    _weekSummary = _summaryOf(walks);
    emit(
      WalkFeedState.loaded(
        walks: walks,
        tracker: _tracker,
        weekSummary: _weekSummary,
      ),
    );
  }

  PeriodSummary _summaryOf(List<Walk> walks) => WalkStatsPolicy.periodStats(
    walks,
    StatsPeriod.week,
    _clock.now(),
  ).summary;

  Future<void> _watchWalks() async {
    // 위젯 테스트의 가짜 비동기에서 끝난 스트림의 cancel 을 기다리면 멈추므로 기다리지 않는다.
    unawaited(_walksSubscription?.cancel());
    if (isClosed) return;

    _walks = null;
    emit(const WalkFeedState.loading());
    _walksSubscription = _useCase.watchWalks().listen(_onWalks);
  }

  void _onWalks(Result<List<Walk>> result) {
    if (isClosed) return;
    switch (result) {
      case Ok(value: final walks):
        _walks = walks;
        _weekSummary = _summaryOf(walks);
        emit(
          WalkFeedState.loaded(
            walks: walks,
            tracker: _tracker,
            weekSummary: _weekSummary,
          ),
        );
      case Err(:final failure):
        _walks = null;
        emit(WalkFeedState.failure(failure));
    }
  }

  void _onTracker(TrackerState tracker) {
    if (isClosed) return;
    _tracker = tracker;
    final walks = _walks;
    // 목록이 아직 없거나 실패 상태면 보관만 한다.
    if (walks == null || state is! WalkFeedLoaded) return;
    emit(
      WalkFeedState.loaded(
        walks: walks,
        tracker: tracker,
        weekSummary: _weekSummary,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _walksSubscription?.cancel();
    await _trackerSubscription?.cancel();
    return super.close();
  }
}
