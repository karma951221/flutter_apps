import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

import '../../domain/tracking/entity/tracker_state.dart';
import '../../domain/tracking/entity/tracking_notice.dart';
import '../../domain/tracking/entity/walk_session.dart';
import '../../domain/tracking/policy/walk_tracking_policy.dart';
import '../../domain/tracking/repository/walk_tracker.dart';
import '../../domain/walk/entity/geo_point.dart';
import '../../domain/walk/entity/walk_track_point.dart';

/// 등록 타입이 [WalkTracker] 라 인터페이스에 dispose 가 없으므로 함수로 닫는다.
FutureOr<void> disposeWalkTracker(WalkTracker tracker) =>
    tracker is GeolocatorWalkTracker ? tracker.dispose() : null;

@LazySingleton(as: WalkTracker, dispose: disposeWalkTracker)
class GeolocatorWalkTracker implements WalkTracker {
  GeolocatorWalkTracker(this._gateway, this._clock)
    : _access = LocationAccess(_gateway);

  static const _policy = WalkTrackingPolicy();
  static const _distanceFilter = 3;

  final LocationGateway _gateway;
  final Clock _clock;

  /// 서비스 → 권한 순서로 확인하고, 권한은 세션당 한 번만 묻는다.
  final LocationAccess _access;
  final StreamController<TrackerState> _controller =
      StreamController<TrackerState>.broadcast();

  TrackerState _state = const TrackerState.idle();
  StreamSubscription<Position>? _sub;

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
      switch (await _access.ensure()) {
        case LocationAccessStatus.serviceDisabled:
          return const Err(
            Failure.validation(
              failureCode: FailureCode.locationServiceDisabled,
            ),
          );
        case LocationAccessStatus.permissionDenied:
          return const Err(
            Failure.forbidden(
              failureCode: FailureCode.locationPermissionDenied,
            ),
          );
        case LocationAccessStatus.granted:
          break;
      }

      // await 사이에 다른 start 가 끼어들었을 수 있다.
      if (_state is TrackerTracking) {
        return const Err(
          Failure.validation(
            failureCode: FailureCode.walkTrackingAlreadyActive,
          ),
        );
      }

      await _sub?.cancel();
      _sub = _gateway
          .positionStream(_settings(notice))
          .listen(_onPosition, onError: _onError);
      _emit(
        TrackerState.tracking(
          WalkSession(
            dogIds: dogIds,
            startedAt: _clock.now(),
            points: const [],
            distanceMeters: 0,
          ),
        ),
      );
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
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
      return;
    }
    _emit(
      TrackerState.tracking(
        WalkSession(
          dogIds: session.dogIds,
          startedAt: session.startedAt,
          points: [...session.points, next],
          distanceMeters: session.distanceMeters + step,
        ),
      ),
    );
  }

  /// 일시적 위치 오류로 산책을 끊지 않는다.
  void _onError(Object error) =>
      debugPrint('walk tracker stream error: $error');

  @override
  Future<Result<WalkSession>> stop() async {
    final state = _state;
    if (state is! TrackerTracking) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }
    await _sub?.cancel();
    _sub = null;
    final s = state.session;
    final finished = WalkSession(
      dogIds: s.dogIds,
      startedAt: s.startedAt,
      endedAt: _clock.now(),
      points: s.points,
      distanceMeters: s.distanceMeters,
    );
    _emit(TrackerState.finished(finished));
    return Ok(finished);
  }

  /// finished → idle 만 허용한다. 추적 중에는 무시해 진행 중인 산책을 지키지 않는 호출이 없게 한다.
  @override
  Future<void> clear() async {
    if (_state is TrackerFinished) _emit(const TrackerState.idle());
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _controller.close();
  }
}
