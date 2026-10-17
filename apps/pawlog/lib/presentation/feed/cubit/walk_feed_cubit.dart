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

  /// 한 번에 더 읽는 산책 수.
  static const pageSize = 30;

  final WalkUseCase _useCase;
  final Clock _clock;

  StreamSubscription<Result<List<Walk>>>? _walksSubscription;
  StreamSubscription<Result<List<Walk>>>? _weekSubscription;
  StreamSubscription<TrackerState>? _trackerSubscription;
  List<Walk>? _walks;
  TrackerState _tracker = const TrackerState.idle();
  PeriodSummary _weekSummary = PeriodSummary.empty;

  /// 이번 주 시작부터 시작한 산책 — 요약은 페이지가 아니라 이 목록으로 센다.
  List<Walk>? _weekWalks;
  DateTime? _weekStart;

  /// 지금 구독 중인 산책 수 상한. 처음엔 한 페이지, [loadMore] 마다 한 페이지씩 는다.
  int _limit = pageSize;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  /// 즐겨찾기만 보기 — 화면 상태라 저장하지 않는다(앱을 다시 열면 전체).
  bool _favoritesOnly = false;

  /// 내보내기 · 가져오기가 진행 중이면 다시 누른 것은 무시한다 — 공유 시트 · 파일 고르기가
  /// 두 번 뜨지 않게.
  bool _backupBusy = false;

  /// 추적기 상태를 먼저 읽고 추적 · 요약 · 목록 스트림을 구독한다.
  Future<void> start() async {
    await _trackerSubscription?.cancel();
    if (isClosed) return;
    // 구독을 먼저 건다 — `trackerStates` 는 현재값을 내지 않으므로 놓치지 않게.
    _trackerSubscription = _useCase.trackerStates.listen(_onTracker);
    _tracker = _useCase.trackerState;
    await _reload();
  }

  /// 실패 뒤 다시 읽는다. 추적 구독은 그대로 두고 요약 · 목록 구독을 첫 페이지부터 다시 건다.
  Future<void> retry() => _reload();

  /// 다음 페이지를 읽는다. loaded 가 아니거나, 읽는 중이거나, 더 없으면 아무것도 하지 않는다.
  void loadMore() {
    final current = state;
    if (isClosed || current is! WalkFeedLoaded || !_hasMore || _isLoadingMore) {
      return;
    }
    _limit += pageSize;
    _isLoadingMore = true;
    emit(current.copyWith(isLoadingMore: true));
    _subscribeWalks();
  }

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

  /// 이번 주 요약을 지금 시각 기준으로 다시 잡는다 — 앱이 주 경계를 넘긴 채 백그라운드에
  /// 있다 돌아오면 스트림 값이 없어도 요약이 바뀌어야 한다. 주가 바뀌었으면 들고 있던
  /// 목록으로 바로 다시 세고(새 주는 옛 주 시작 이후의 부분이다) 새 주 시작으로 다시
  /// 구독한다. 목록이 아직 없거나 loaded 가 아니면 아무것도 하지 않는다.
  void refreshWeekSummary() {
    final current = state;
    if (isClosed || current is! WalkFeedLoaded) return;
    if (_weekStartNow() == _weekStart) return;
    final weekWalks = _weekWalks;
    if (weekWalks != null) {
      _weekSummary = _summaryOf(weekWalks);
      emit(current.copyWith(weekSummary: _weekSummary));
    }
    _subscribeWeek();
  }

  /// 즐겨찾기만 보기를 켜고 끈다. 첫 페이지부터 다시 구독하고, 새 목록이 올 때까지 지금
  /// 목록을 둔다. loaded 가 아니면 아무것도 하지 않는다.
  void toggleFavoritesOnly() {
    final current = state;
    if (isClosed || current is! WalkFeedLoaded) return;
    _favoritesOnly = !_favoritesOnly;
    _limit = pageSize;
    _isLoadingMore = false;
    emit(current.copyWith(favoritesOnly: _favoritesOnly, isLoadingMore: false));
    _subscribeWalks();
  }

  DateTime _weekStartNow() =>
      WalkStatsPolicy.periodRange(StatsPeriod.week, _clock.now()).start;

  PeriodSummary _summaryOf(List<Walk> walks) => WalkStatsPolicy.periodStats(
    walks,
    StatsPeriod.week,
    _clock.now(),
  ).summary;

  Future<void> _reload() async {
    if (isClosed) return;
    _walks = null;
    _limit = pageSize;
    _isLoadingMore = false;
    emit(const WalkFeedState.loading());
    // 요약을 먼저 걸어 보통은 첫 loaded 에 요약이 실린다.
    _subscribeWeek();
    _subscribeWalks();
  }

  void _subscribeWalks() {
    // 위젯 테스트의 가짜 비동기에서 끝난 스트림의 cancel 을 기다리면 멈추므로 기다리지 않는다.
    unawaited(_walksSubscription?.cancel());
    _walksSubscription = _useCase
        .watchRecentWalks(limit: _limit, favoritesOnly: _favoritesOnly)
        .listen(_onWalks);
  }

  void _subscribeWeek() {
    unawaited(_weekSubscription?.cancel());
    final from = _weekStartNow();
    _weekStart = from;
    _weekSubscription = _useCase.watchWalksSince(from).listen(_onWeek);
  }

  void _onWalks(Result<List<Walk>> result) {
    if (isClosed) return;
    switch (result) {
      case Ok(value: final walks):
        _walks = walks;
        _hasMore = walks.length == _limit;
        _isLoadingMore = false;
        _emitLoaded();
      case Err(:final failure):
        _walks = null;
        _isLoadingMore = false;
        emit(WalkFeedState.failure(failure));
    }
  }

  /// 요약 스트림이 실패하면 지난 요약을 둔다 — 요약 줄 때문에 피드 전체를 실패로 돌리지 않는다.
  void _onWeek(Result<List<Walk>> result) {
    if (isClosed) return;
    if (result case Ok(value: final walks)) {
      _weekWalks = walks;
      _weekSummary = _summaryOf(walks);
      final current = state;
      if (current is WalkFeedLoaded) {
        emit(current.copyWith(weekSummary: _weekSummary));
      }
    }
  }

  void _onTracker(TrackerState tracker) {
    if (isClosed) return;
    _tracker = tracker;
    // 목록이 아직 없거나 실패 상태면 보관만 한다.
    if (state is! WalkFeedLoaded) return;
    _emitLoaded();
  }

  void _emitLoaded() {
    final walks = _walks;
    if (walks == null) return;
    emit(
      WalkFeedState.loaded(
        walks: walks,
        tracker: _tracker,
        weekSummary: _weekSummary,
        favoritesOnly: _favoritesOnly,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _walksSubscription?.cancel();
    await _weekSubscription?.cancel();
    await _trackerSubscription?.cancel();
    return super.close();
  }
}
