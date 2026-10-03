import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/geo_point.dart';
import '../../domain/entity/tracker_state.dart';
import '../../domain/entity/tracking_notice.dart';
import '../../domain/entity/walk_session.dart';
import '../../domain/entity/walk_track_point.dart';
import '../../domain/policy/walk_tracking_policy.dart';
import '../../domain/repository/walk_tracker.dart';
import '../location/location_gateway.dart';

/// 등록 타입이 [WalkTracker] 라 인터페이스에 dispose 가 없으므로 함수로 닫는다.
FutureOr<void> disposeWalkTracker(WalkTracker tracker) =>
    tracker is GeolocatorWalkTracker ? tracker.dispose() : null;

@LazySingleton(as: WalkTracker, dispose: disposeWalkTracker)
class GeolocatorWalkTracker implements WalkTracker {
  GeolocatorWalkTracker(LocationGateway gateway)
    : this.withClock(gateway, DateTime.now);

  @visibleForTesting
  GeolocatorWalkTracker.withClock(this._gateway, this._now);

  static const _policy = WalkTrackingPolicy();
  static const _distanceFilter = 3;

  final LocationGateway _gateway;
  final DateTime Function() _now;
  final StreamController<TrackerState> _controller =
      StreamController<TrackerState>.broadcast();

  TrackerState _state = const TrackerState.idle();
  StreamSubscription<Position>? _sub;

  /// 이번 세션에서 사용자가 권한 요청을 거부했는지. Android 는 첫 거부 뒤에도
  /// `denied` 를 돌려주므로 기억하지 않으면 시스템 다이얼로그가 계속 뜬다.
  bool _requestDeclined = false;

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
      if (!await _gateway.isLocationServiceEnabled()) {
        return const Err(
          Failure.validation(failureCode: FailureCode.locationServiceDisabled),
        );
      }

      var permission = await _gateway.checkPermission();
      if (permission == LocationPermission.denied && !_requestDeclined) {
        permission = await _gateway.requestPermission();
        _requestDeclined =
            permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const Err(
          Failure.forbidden(failureCode: FailureCode.locationPermissionDenied),
        );
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
            startedAt: _now(),
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
        : _gateway.distanceBetween(previous.point, next.point);

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
      return const Err(
        Failure.validation(failureCode: FailureCode.walkNotFound),
      );
    }
    await _sub?.cancel();
    _sub = null;
    final s = state.session;
    final finished = WalkSession(
      dogIds: s.dogIds,
      startedAt: s.startedAt,
      endedAt: _now(),
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
