import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/dog.dart';
import '../../domain/entity/tracker_state.dart';
import '../../domain/entity/tracking_notice.dart';
import '../../domain/entity/walk_session.dart';
import '../../domain/usecase/walk_use_case.dart';
import 'active_walk_state.dart';

@injectable
class ActiveWalkCubit extends Cubit<ActiveWalkState> {
  ActiveWalkCubit(WalkUseCase useCase) : this.withClock(useCase, DateTime.now);

  /// 테스트에서 시각을 고정하려고 둔 생성자. DI 는 위 생성자를 쓴다.
  ActiveWalkCubit.withClock(this._useCase, this._now)
    : super(const ActiveWalkState.loading());

  final WalkUseCase _useCase;
  final DateTime Function() _now;

  StreamSubscription<TrackerState>? _subscription;
  StreamSubscription<Result<List<Dog>>>? _dogsSubscription;
  Timer? _timer;
  TrackingNotice? _notice;
  bool _stopping = false;

  /// 추적기 상태를 먼저 보고(재진입) 구독한 뒤, 추적 중이 아니면 반려견을 읽는다.
  Future<void> load() async {
    await _subscription?.cancel();
    if (isClosed) return;

    // 구독을 먼저 건다 — `states` 는 현재값을 내지 않으므로 읽는 사이의 변화를 놓치지 않게.
    _subscription = _useCase.trackerStates.listen(_onTrackerState);
    switch (_useCase.trackerState) {
      case TrackerTracking(:final session):
        _enterTracking(session);
      case TrackerFinished(:final session):
        _emitStopped(session);
      case TrackerIdle():
        await _loadDogs();
    }
  }

  File photoFile(String relativePath) => _useCase.photoFile(relativePath);

  void toggleDog(String id) {
    final current = state;
    if (current is! ActiveWalkSelectingDogs) return;
    final next = {...current.selectedIds};
    if (!next.remove(id)) next.add(id);
    emit(current.copyWith(selectedIds: next));
  }

  /// [notice] 는 Android 포그라운드 알림 문구다. 재시도를 위해 기억해 둔다.
  Future<void> start(TrackingNotice notice) async {
    final (dogs, selectedIds) = switch (state) {
      ActiveWalkSelectingDogs(:final dogs, :final selectedIds) ||
      ActiveWalkFailure(:final dogs, :final selectedIds) => (dogs, selectedIds),
      _ => (const <Dog>[], const <String>{}),
    };
    if (selectedIds.isEmpty) return;

    _notice = notice;
    // 시작하면 목록 변화는 더 필요 없다.
    unawaited(_cancelDogs());
    emit(ActiveWalkState.starting(dogs: dogs, selectedIds: selectedIds));
    final result = await _useCase.startWalk(
      dogIds: [
        for (final dog in dogs)
          if (selectedIds.contains(dog.id)) dog.id,
      ],
      notice: notice,
    );
    if (isClosed) return;

    switch (result) {
      case Ok():
        // 스트림이 먼저 `tracking` 을 냈다면 이미 상태가 바뀌어 있다.
        if (state is ActiveWalkStarting) {
          if (_useCase.trackerState case TrackerTracking(:final session)) {
            _enterTracking(session);
          }
        }
      case Err(:final failure):
        _emitFailure(failure, dogs, selectedIds);
    }
  }

  Future<void> stop() async {
    if (state is! ActiveWalkTracking || _stopping) return;
    _stopping = true;
    final result = await _useCase.stopWalk();
    _stopping = false;
    if (isClosed) return;

    switch (result) {
      case Ok(value: final session):
        _emitStopped(session);
      case Err(:final failure):
        _emitFailure(failure, const [], const {});
    }
  }

  Future<void> retry() async {
    final current = state;
    final notice = _notice;
    if (current is ActiveWalkFailure &&
        current.selectedIds.isNotEmpty &&
        notice != null) {
      await start(notice);
    } else {
      await load();
    }
  }

  /// 반려견을 구독한다. 첫 값까지 기다려서, 반려견 화면에서 등록하고 돌아오면
  /// 목록이 저절로 갱신된다. 추적을 시작하거나 닫히면 끊는다.
  Future<void> _loadDogs() async {
    await _cancelDogs();
    if (isClosed) return;

    final first = Completer<void>();
    _dogsSubscription = _useCase.watchDogs().listen((result) {
      _onDogs(result);
      if (!first.isCompleted) first.complete();
    });
    await first.future;
  }

  void _onDogs(Result<List<Dog>> result) {
    if (isClosed) return;
    switch (result) {
      case Err(:final failure):
        if (state is ActiveWalkLoading || state is ActiveWalkSelectingDogs) {
          _emitFailure(failure, const [], const {});
        }
      case Ok(value: final dogs):
        final ids = {for (final dog in dogs) dog.id};
        switch (state) {
          case ActiveWalkSelectingDogs(dogs: final before, :final selectedIds):
            final known = {for (final dog in before) dog.id};
            emit(
              ActiveWalkState.selectingDogs(
                dogs: dogs,
                selectedIds: {
                  for (final id in ids)
                    if (selectedIds.contains(id) || !known.contains(id)) id,
                },
              ),
            );
          case ActiveWalkLoading() || ActiveWalkFailure():
            emit(ActiveWalkState.selectingDogs(dogs: dogs, selectedIds: ids));
          default:
            break;
        }
    }
  }

  Future<void> _cancelDogs() async {
    final subscription = _dogsSubscription;
    _dogsSubscription = null;
    await subscription?.cancel();
  }

  void _onTrackerState(TrackerState tracker) {
    if (isClosed) return;
    switch (tracker) {
      case TrackerTracking(:final session):
        _enterTracking(session);
      case TrackerFinished(:final session):
        _emitStopped(session);
      case TrackerIdle():
        break;
    }
  }

  void _enterTracking(WalkSession session) {
    unawaited(_cancelDogs());
    emit(
      ActiveWalkState.tracking(
        session: session,
        elapsed: session.elapsedAt(_now()),
      ),
    );
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// 틱을 누적하지 않고 매번 시작 시각 기준으로 다시 계산한다.
  void _tick() {
    final current = state;
    if (isClosed || current is! ActiveWalkTracking) return;
    emit(current.copyWith(elapsed: current.session.elapsedAt(_now())));
  }

  /// 구독과 `stop()` 결과 중 먼저 온 쪽만 낸다.
  void _emitStopped(WalkSession session) {
    _cancelTimer();
    unawaited(_cancelDogs());
    if (state is ActiveWalkStopped) return;
    emit(ActiveWalkState.stopped(session));
  }

  void _emitFailure(Failure failure, List<Dog> dogs, Set<String> selectedIds) {
    _cancelTimer();
    emit(
      ActiveWalkState.failure(
        failure: failure,
        dogs: dogs,
        selectedIds: selectedIds,
      ),
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() async {
    _cancelTimer();
    await _cancelDogs();
    await _subscription?.cancel();
    return super.close();
  }
}
