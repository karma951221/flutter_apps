import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';

class MockLocationGateway extends Mock implements LocationGateway {}

const _notice = TrackingNotice(title: '산책 중', text: '기록하고 있어요');

Position _pos(double lat, {double accuracy = 5, DateTime? at}) => Position(
  latitude: lat,
  longitude: 127,
  timestamp: at ?? t0,
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late MockLocationGateway gateway;
  late StreamController<Position> positions;
  late GeolocatorWalkTracker tracker;
  var clock = t0;

  setUpAll(() {
    registerFallbackValue(const LocationSettings());
    registerFallbackValue(const GeoPoint(lat: 0, lng: 0));
  });

  setUp(() {
    clock = t0;
    gateway = MockLocationGateway();
    positions = StreamController<Position>.broadcast();
    tracker = GeolocatorWalkTracker.withClock(gateway, () => clock);
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);
    when(
      () => gateway.positionStream(any()),
    ).thenAnswer((_) => positions.stream);
    when(() => gateway.distanceBetween(any(), any())).thenReturn(10);
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await tracker.dispose();
    unawaited(positions.close());
  });

  Future<void> started() async {
    final r = await tracker.start(dogIds: const ['d1'], notice: _notice);
    expect(r, isA<Ok<void>>());
  }

  WalkSession session() => (tracker.current as TrackerTracking).session;

  Failure failureOf(Result<Object?> r) => (r as Err).failure;

  test('서비스가 꺼져 있으면 locationServiceDisabled', () async {
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => false);

    final r = await tracker.start(dogIds: const ['d1'], notice: _notice);

    expect(failureOf(r).failureCode, FailureCode.locationServiceDisabled);
    expect(tracker.current, isA<TrackerIdle>());
  });

  test('권한을 거부하면 locationPermissionDenied 이고 같은 세션에서 다시 묻지 않는다', () async {
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);
    when(
      () => gateway.requestPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);

    final first = await tracker.start(dogIds: const ['d1'], notice: _notice);
    final second = await tracker.start(dogIds: const ['d1'], notice: _notice);

    expect(failureOf(first).failureCode, FailureCode.locationPermissionDenied);
    expect(failureOf(second).failureCode, FailureCode.locationPermissionDenied);
    verify(() => gateway.requestPermission()).called(1);
  });

  test('영구 거부면 요청 없이 locationPermissionDenied', () async {
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.deniedForever);

    final r = await tracker.start(dogIds: const ['d1'], notice: _notice);

    expect(failureOf(r).failureCode, FailureCode.locationPermissionDenied);
    verifyNever(() => gateway.requestPermission());
  });

  test('시작하면 tracking 상태를 방출하고 points 는 비어 있다', () async {
    final emitted = <TrackerState>[];
    final sub = tracker.states.listen(emitted.add);

    await started();
    await pumpEventQueue();
    await sub.cancel();

    expect(emitted, hasLength(1));
    expect(session().points, isEmpty);
    expect(session().dogIds, ['d1']);
    expect(session().startedAt, t0);
    expect(session().distanceMeters, 0);
  });

  test('플랫폼별 설정으로 스트림을 구독한다', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await started();
    final android =
        verify(() => gateway.positionStream(captureAny())).captured.single
            as AndroidSettings;
    expect(android.foregroundNotificationConfig?.notificationTitle, '산책 중');
    expect(android.distanceFilter, 3);
    await tracker.stop();

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tracker.clear();
    await started();
    final ios =
        verify(() => gateway.positionStream(captureAny())).captured.single
            as AppleSettings;
    expect(ios.activityType, ActivityType.fitness);
    expect(ios.pauseLocationUpdatesAutomatically, isFalse);
  });

  test('위치가 들어오면 거리와 점이 누적된다', () async {
    await started();

    positions.add(_pos(37.5));
    await pumpEventQueue();
    expect(session().points, hasLength(1));
    expect(session().distanceMeters, 0);

    positions.add(_pos(37.6));
    await pumpEventQueue();
    expect(session().points, hasLength(2));
    expect(session().distanceMeters, 10);
    expect(session().points.last.point, const GeoPoint(lat: 37.6, lng: 127));
    expect(session().points.last.accuracy, 5);
  });

  test('정책이 버린 점은 쌓이지 않는다', () async {
    await started();
    positions.add(_pos(37.5));
    await pumpEventQueue();

    positions.add(_pos(37.6, accuracy: 80));
    await pumpEventQueue();
    expect(session().points, hasLength(1));

    when(() => gateway.distanceBetween(any(), any())).thenReturn(1);
    positions.add(_pos(37.6));
    await pumpEventQueue();
    expect(session().points, hasLength(1));
    expect(session().distanceMeters, 0);
  });

  test('이미 추적 중이면 start 를 거부한다', () async {
    await started();

    final r = await tracker.start(dogIds: const ['d2'], notice: _notice);

    expect(failureOf(r).failureCode, FailureCode.walkTrackingAlreadyActive);
    expect(session().dogIds, ['d1']);
  });

  test('stop 은 endedAt 을 채운 finished 를 주고 구독을 끊는다', () async {
    await started();
    positions.add(_pos(37.5));
    await pumpEventQueue();
    clock = t1;

    final r = await tracker.stop();

    final finished = (r as Ok<WalkSession>).value;
    expect(finished.endedAt, t1);
    expect(finished.points, hasLength(1));
    final state = tracker.current as TrackerFinished;
    expect(state.session, finished);
    expect(positions.hasListener, isFalse);
  });

  test('추적 중이 아니면 stop 은 walkNotFound', () async {
    final r = await tracker.stop();

    expect(failureOf(r).failureCode, FailureCode.walkNotFound);
  });

  test('clear 는 finished 에서만 idle 로 간다', () async {
    await started();

    await tracker.clear();
    expect(tracker.current, isA<TrackerTracking>());

    await tracker.stop();
    await tracker.clear();
    expect(tracker.current, isA<TrackerIdle>());
  });

  test('스트림 오류가 나도 tracking 을 유지한다', () async {
    await started();

    positions.addError(Exception('gps lost'));
    await pumpEventQueue();
    expect(tracker.current, isA<TrackerTracking>());

    positions.add(_pos(37.5));
    await pumpEventQueue();
    expect(session().points, hasLength(1));
  });
}
