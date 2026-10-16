import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

import '../../domain/tracking/entity/tracker_state.dart';
import '../../domain/tracking/entity/tracking_notice.dart';
import '../../domain/tracking/entity/walk_session.dart';
import '../../domain/tracking/policy/walk_tracking_policy.dart';
import '../../domain/tracking/repository/active_walk_store.dart';
import '../../domain/tracking/repository/walk_tracker.dart';
import '../../domain/walk/entity/geo_point.dart';
import '../../domain/walk/entity/walk_track_point.dart';

/// 등록 타입이 [WalkTracker] 라 인터페이스에 dispose 가 없으므로 함수로 닫는다.
FutureOr<void> disposeWalkTracker(WalkTracker tracker) =>
    tracker is GeolocatorWalkTracker ? tracker.dispose() : null;

@LazySingleton(as: WalkTracker, dispose: disposeWalkTracker)
class GeolocatorWalkTracker implements WalkTracker {
  GeolocatorWalkTracker(this._gateway, this._clock, this._store)
    : _access = LocationAccess(_gateway);

  static const _policy = WalkTrackingPolicy();
  static const _distanceFilter = 3;

  final LocationGateway _gateway;
  final Clock _clock;

  /// 앱이 죽어도 다음 실행에 되살리도록 진행 중 세션을 써 둔다.
  final ActiveWalkStore _store;

  /// 서비스 → 권한 순서로 확인하고, 권한은 세션당 한 번만 묻는다.
  final LocationAccess _access;
  final StreamController<TrackerState> _controller =
      StreamController<TrackerState>.broadcast();

  TrackerState _state = const TrackerState.idle();
  StreamSubscription<Position>? _sub;

  /// `resume` 이 같은 알림 문구로 다시 구독하도록 기억한다.
  TrackingNotice? _notice;

  /// 재개 뒤 첫 수락 점은 멈춘 동안 옮긴 거리를 걸은 거리로 세지 않는다.
  bool _skipNextStep = false;

  /// 저장소 쓰기를 순서대로 잇는 큐. 실패는 알리기만 하고 추적은 이어 간다.
  Future<void> _writes = Future.value();

  void _enqueue(Future<void> Function() op) {
    _writes = _writes
        .then((_) => op())
        .catchError((Object e) => debugPrint('active walk store: $e'));
  }

  /// 지금까지 넣은 쓰기가 모두 끝날 때 완료된다.
  @visibleForTesting
  Future<void> get pendingWrites => _writes;

  @override
  TrackerState get current => _state;

  @override
  Stream<TrackerState> get states => _controller.stream;

  void _emit(TrackerState state) {
    _state = state;
    if (!_controller.isClosed) _controller.add(state);
  }

  @override
  Future<Result<void>> start({
    required List<String> dogIds,
    required TrackingNotice notice,
  }) async {
    if (_state is TrackerTracking) {
      return const Err(
        Failure.validation(failureCode: FailureCode.walkTrackingAlreadyActive),
      );
    }
    try {
      if (await _checkAccess() case final Failure failure) return Err(failure);

      // await 사이에 다른 start 가 끼어들었을 수 있다.
      if (_state is TrackerTracking) {
        return const Err(
          Failure.validation(
            failureCode: FailureCode.walkTrackingAlreadyActive,
          ),
        );
      }

      _notice = notice;
      _skipNextStep = false;
      await _subscribe(notice);
      final session = WalkSession(
        dogIds: dogIds,
        startedAt: _clock.now(),
        points: const [],
        distanceMeters: 0,
      );
      _emit(TrackerState.tracking(session));
      _enqueue(() => _store.begin(session, notice));
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  @override
  Future<void> restore() async {
    if (_state is! TrackerIdle) return;
    try {
      final snapshot = await _store.load();
      if (snapshot == null || _state is! TrackerIdle) return;
      final session = snapshot.session;
      _notice = snapshot.notice;
      if (session.endedAt != null) {
        _emit(TrackerState.finished(session));
        return;
      }
      // 죽어 있던 동안도 걸은 것으로 센다. 첫 새 점의 거리를 그대로 더한다.
      _skipNextStep = false;
      final failure = await _checkAccess();
      if (_state is! TrackerIdle) return;
      if (failure != null) {
        _emit(TrackerState.tracking(session, locationError: failure));
        return;
      }
      await _subscribe(snapshot.notice);
      _emit(TrackerState.tracking(session));
    } catch (error) {
      debugPrint('walk tracker restore: $error');
    }
  }

  @override
  Future<Result<void>> resume() async {
    final notice = _notice;
    if (_state is! TrackerTracking || notice == null) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }
    try {
      final failure = await _checkAccess();
      // await 사이에 멈췄을 수 있다.
      final state = _state;
      if (state is! TrackerTracking) {
        return const Err(
          Failure.notFound(failureCode: FailureCode.walkNotFound),
        );
      }
      if (failure != null) {
        _emit(TrackerState.tracking(state.session, locationError: failure));
        return Err(failure);
      }
      await _subscribe(notice);
      _emit(TrackerState.tracking(state.session));
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  /// 서비스 → 권한 순서로 확인한다. 쓸 수 있으면 null.
  Future<Failure?> _checkAccess() async => switch (await _access.ensure()) {
    LocationAccessStatus.serviceDisabled => const Failure.validation(
      failureCode: FailureCode.locationServiceDisabled,
    ),
    LocationAccessStatus.permissionDenied => const Failure.forbidden(
      failureCode: FailureCode.locationPermissionDenied,
    ),
    LocationAccessStatus.granted => null,
  };

  Future<void> _subscribe(TrackingNotice notice) async {
    await _sub?.cancel();
    _sub = _gateway
        .positionStream(_settings(notice))
        .listen(_onPosition, onError: _onError);
  }

  LocationSettings _settings(TrackingNotice notice) =>
      switch (defaultTargetPlatform) {
        TargetPlatform.android => AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: _distanceFilter,
          intervalDuration: const Duration(seconds: 2),
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: notice.title,
            notificationText: notice.text,
            enableWakeLock: true,
          ),
        ),
        TargetPlatform.iOS => AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: _distanceFilter,
          activityType: ActivityType.fitness,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
          pauseLocationUpdatesAutomatically: false,
        ),
        _ => const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: _distanceFilter,
        ),
      };

  void _onPosition(Position position) {
    final state = _state;
    if (state is! TrackerTracking) return;
    final session = state.session;

    if (session.isPaused) {
      // 멈춤 중에도 위치는 들어오고 있다. 점은 버리고 오류만 지운다.
      if (state.locationError != null) _emit(TrackerState.tracking(session));
      return;
    }

    final next = WalkTrackPoint(
      point: GeoPoint(lat: position.latitude, lng: position.longitude),
      recordedAt: position.timestamp,
      accuracy: position.accuracy,
    );
    final previous = session.points.lastOrNull;
    final step = previous == null
        ? 0.0
        : _gateway.distanceBetween(
            previous.point.lat,
            previous.point.lng,
            next.point.lat,
            next.point.lng,
          );

    if (!_policy.accept(previous: previous, next: next, stepMeters: step)) {
      // 버린 점이라도 위치는 다시 들어오고 있다.
      if (state.locationError != null) _emit(TrackerState.tracking(session));
      return;
    }
    final added = _skipNextStep ? 0.0 : step;
    _skipNextStep = false;
    final updated = session.copyWith(
      points: [...session.points, next],
      distanceMeters: session.distanceMeters + added,
    );
    _emit(TrackerState.tracking(updated));
    final seq = updated.points.length - 1;
    _enqueue(() => _store.appendPoint(seq, next, updated.distanceMeters));
  }

  @override
  Future<Result<void>> pause() async {
    final state = _state;
    if (state is! TrackerTracking) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }
    if (state.session.isPaused) return const Ok(null);
    final paused = state.session.copyWith(pausedAt: _clock.now());
    _emit(TrackerState.tracking(paused, locationError: state.locationError));
    _enqueue(() => _store.updateTiming(paused));
    return const Ok(null);
  }

  @override
  Future<Result<void>> unpause() async {
    final state = _state;
    if (state is! TrackerTracking) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }
    final session = state.session;
    if (!session.isPaused) return const Ok(null);
    _skipNextStep = true;
    final resumed = _closePause(session, _clock.now());
    _emit(TrackerState.tracking(resumed, locationError: state.locationError));
    _enqueue(() => _store.updateTiming(resumed));
    return const Ok(null);
  }

  /// 진행 중인 멈춤을 [now] 에 닫아 `pausedDuration` 에 더한다.
  static WalkSession _closePause(WalkSession session, DateTime now) {
    final pausedAt = session.pausedAt;
    if (pausedAt == null) return session;
    final length = now.isBefore(pausedAt)
        ? Duration.zero
        : now.difference(pausedAt);
    return session.copyWith(
      pausedDuration: session.pausedDuration + length,
      pausedAt: null,
    );
  }

  /// 위치 오류로 산책을 끊지 않는다. 화면이 알리고 `resume` 으로 다시 받게
  /// 상태에만 싣는다.
  void _onError(Object error) {
    debugPrint('walk tracker stream error: $error');
    final state = _state;
    if (state is! TrackerTracking) return;
    _emit(
      TrackerState.tracking(state.session, locationError: _failureOf(error)),
    );
  }

  static Failure _failureOf(Object error) => switch (error) {
    LocationServiceDisabledException() => const Failure.validation(
      failureCode: FailureCode.locationServiceDisabled,
    ),
    PermissionDeniedException() => const Failure.forbidden(
      failureCode: FailureCode.locationPermissionDenied,
    ),
    _ => Failure.unknown(
      message: error.toString(),
      failureCode: FailureCode.locationStreamFailed,
    ),
  };

  @override
  Future<Result<WalkSession>> stop() async {
    final state = _state;
    if (state is! TrackerTracking) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }
    await _sub?.cancel();
    _sub = null;
    _skipNextStep = false;
    final now = _clock.now();
    final finished = _closePause(state.session, now).copyWith(endedAt: now);
    _emit(TrackerState.finished(finished));
    _enqueue(() => _store.updateTiming(finished));
    return Ok(finished);
  }

  @override
  Future<void> openAppSettings() => _access.permission.openSettings();

  @override
  Future<void> openLocationSettings() => _access.openLocationSettings();

  /// finished → idle 만 허용한다. 추적 중에는 무시해 진행 중인 산책을 지키지 않는 호출이 없게 한다.
  @override
  Future<void> clear() async {
    if (_state is! TrackerFinished) return;
    _emit(const TrackerState.idle());
    _enqueue(_store.clear);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _controller.close();
  }
}
