import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/tracker_state.dart';
import '../../domain/entity/walk.dart';
import '../../domain/usecase/walk_use_case.dart';
import 'walk_feed_state.dart';

@injectable
class WalkFeedCubit extends Cubit<WalkFeedState> {
  WalkFeedCubit(this._useCase) : super(const WalkFeedState.loading());

  final WalkUseCase _useCase;

  StreamSubscription<Result<List<Walk>>>? _walksSubscription;
  StreamSubscription<TrackerState>? _trackerSubscription;
  List<Walk>? _walks;
  TrackerState _tracker = const TrackerState.idle();

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
        emit(WalkFeedState.loaded(walks: walks, tracker: _tracker));
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
    emit(WalkFeedState.loaded(walks: walks, tracker: tracker));
  }

  @override
  Future<void> close() async {
    await _walksSubscription?.cancel();
    await _trackerSubscription?.cancel();
    return super.close();
  }
}
