import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/data/tracking/geolocator_walk_tracker.dart';
import 'package:pawlog/domain/tracking/entity/active_walk_snapshot.dart';
import 'package:pawlog/domain/tracking/entity/tracker_state.dart';
import 'package:pawlog/domain/tracking/entity/tracking_notice.dart';
import 'package:pawlog/domain/tracking/entity/walk_session.dart';
import 'package:pawlog/domain/tracking/repository/active_walk_store.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';

import '../../support/fakes.dart';

class MockLocationGateway extends Mock implements LocationGateway {}

class MockActiveWalkStore extends Mock implements ActiveWalkStore {}

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
  late MockActiveWalkStore store;
  late GeolocatorWalkTracker tracker;
  var clock = t0;

  setUpAll(() {
    registerFallbackValue(const LocationSettings());
    registerFallbackValue(
      WalkSession(
        dogIds: const [],
        startedAt: t0,
        points: const [],
        distanceMeters: 0,
      ),
    );
    registerFallbackValue(_notice);
    registerFallbackValue(trackPoint(0));
  });

  setUp(() {
    clock = t0;
    gateway = MockLocationGateway();
    positions = StreamController<Position>.broadcast();
    store = MockActiveWalkStore();
    tracker = GeolocatorWalkTracker(gateway, FakeClock(() => clock), store);
    when(() => store.load()).thenAnswer((_) async => null);
    when(() => store.begin(any(), any())).thenAnswer((_) async {});
    when(() => store.appendPoint(any(), any(), any())).thenAnswer((_) async {});
    when(() => store.updateTiming(any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);
    when(
      () => gateway.positionStream(any()),
    ).thenAnswer((_) => positions.stream);
    when(
      () => gateway.distanceBetween(any(), any(), any(), any()),
    ).thenReturn(10);
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

    when(
      () => gateway.distanceBetween(any(), any(), any(), any()),
    ).thenReturn(1);
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

  test('스트림 오류가 나도 tracking 을 유지하고 오류를 상태에 싣는다', () async {
    await started();

    positions.addError(Exception('gps lost'));
    await pumpEventQueue();
    final state = tracker.current as TrackerTracking;
    expect(state.locationError?.failureCode, FailureCode.locationStreamFailed);

    positions.add(_pos(37.5));
    await pumpEventQueue();
    expect(session().points, hasLength(1));
    expect((tracker.current as TrackerTracking).locationError, isNull);
  });

  test('스트림이 서비스 꺼짐 · 권한 거부를 내면 그 코드로 싣는다', () async {
    await started();

    positions.addError(const LocationServiceDisabledException());
    await pumpEventQueue();
    expect(
      (tracker.current as TrackerTracking).locationError?.failureCode,
      FailureCode.locationServiceDisabled,
    );

    positions.addError(const PermissionDeniedException('denied'));
    await pumpEventQueue();
    expect(
      (tracker.current as TrackerTracking).locationError?.failureCode,
      FailureCode.locationPermissionDenied,
    );
  });

  test('resume 은 세션을 지킨 채 스트림을 다시 구독하고 오류를 지운다', () async {
    await started();
    positions.add(_pos(37.5));
    positions.addError(Exception('gps lost'));
    await pumpEventQueue();

    final r = await tracker.resume();

    expect(r, isA<Ok<void>>());
    verify(() => gateway.positionStream(any())).called(2);
    final state = tracker.current as TrackerTracking;
    expect(state.locationError, isNull);
    expect(state.session.points, hasLength(1));
  });

  test('resume 때 서비스가 꺼져 있으면 실패를 돌려주고 상태에도 싣는다', () async {
    await started();
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => false);

    final r = await tracker.resume();

    expect(failureOf(r).failureCode, FailureCode.locationServiceDisabled);
    expect(
      (tracker.current as TrackerTracking).locationError?.failureCode,
      FailureCode.locationServiceDisabled,
    );
  });

  test('추적 중이 아니면 resume 은 walkNotFound', () async {
    final r = await tracker.resume();

    expect(failureOf(r).failureCode, FailureCode.walkNotFound);
  });

  group('일시정지', () {
    test('pause 는 tracking 을 유지하고 pausedAt 을 지금으로 싣는다', () async {
      await started();
      final emitted = <TrackerState>[];
      final sub = tracker.states.listen(emitted.add);
      clock = t0.add(const Duration(minutes: 10));

      final r = await tracker.pause();
      await pumpEventQueue();
      await sub.cancel();

      expect(r, isA<Ok<void>>());
      expect(tracker.current, isA<TrackerTracking>());
      expect(session().pausedAt, clock);
      expect(session().isPaused, isTrue);
      expect(emitted, hasLength(1));
      expect((emitted.single as TrackerTracking).session.pausedAt, clock);
    });

    test('멈춤 중 들어온 점은 쌓이지 않는다', () async {
      await started();
      positions.add(_pos(37.5));
      await pumpEventQueue();
      await tracker.pause();

      positions.add(_pos(37.6));
      positions.add(_pos(37.7));
      await pumpEventQueue();

      expect(session().points, hasLength(1));
      expect(session().distanceMeters, 0);
      expect(positions.hasListener, isTrue);
    });

    test('unpause 는 pausedAt 을 닫고 멈춘 길이를 pausedDuration 에 더한다', () async {
      await started();
      await tracker.pause();
      clock = t0.add(const Duration(minutes: 5));

      final r = await tracker.unpause();

      expect(r, isA<Ok<void>>());
      expect(session().pausedAt, isNull);
      expect(session().pausedDuration, const Duration(minutes: 5));
    });

    test('재개 뒤 첫 점은 거리를 더하지 않고 그다음부터 더한다', () async {
      await started();
      positions.add(_pos(37.5));
      await pumpEventQueue();
      await tracker.pause();
      positions.add(_pos(37.55));
      await pumpEventQueue();
      await tracker.unpause();

      positions.add(_pos(37.6));
      await pumpEventQueue();
      expect(session().points, hasLength(2));
      expect(session().distanceMeters, 0);

      positions.add(_pos(37.7));
      await pumpEventQueue();
      expect(session().points, hasLength(3));
      expect(session().distanceMeters, 10);
    });

    test('재개 뒤 정책이 버린 점은 거리 0 자리를 쓰지 않는다', () async {
      await started();
      positions.add(_pos(37.5));
      await pumpEventQueue();
      await tracker.pause();
      await tracker.unpause();

      positions.add(_pos(37.6, accuracy: 80));
      await pumpEventQueue();
      expect(session().points, hasLength(1));

      positions.add(_pos(37.6));
      await pumpEventQueue();
      expect(session().points, hasLength(2));
      expect(session().distanceMeters, 0);
    });

    test('멈춤 중 stop 은 마지막 멈춤을 닫아 pausedDuration 에 더한다', () async {
      await started();
      clock = t0.add(const Duration(minutes: 10));
      await tracker.pause();
      clock = t0.add(const Duration(minutes: 13));

      final r = await tracker.stop();

      final finished = (r as Ok<WalkSession>).value;
      expect(finished.endedAt, clock);
      expect(finished.pausedAt, isNull);
      expect(finished.pausedDuration, const Duration(minutes: 3));
      expect(finished.elapsedAt(clock), const Duration(minutes: 10));
    });

    test('stop 은 지난 멈춤 합을 지킨다', () async {
      await started();
      await tracker.pause();
      clock = t0.add(const Duration(minutes: 2));
      await tracker.unpause();
      clock = t1;

      final finished = ((await tracker.stop()) as Ok<WalkSession>).value;

      expect(finished.pausedDuration, const Duration(minutes: 2));
      expect(finished.pausedAt, isNull);
    });

    test('idle 에서 pause · unpause 는 walkNotFound', () async {
      expect(
        failureOf(await tracker.pause()).failureCode,
        FailureCode.walkNotFound,
      );
      expect(
        failureOf(await tracker.unpause()).failureCode,
        FailureCode.walkNotFound,
      );
    });

    test('이미 멈춤 중 pause · 진행 중 unpause 는 Ok 이고 상태를 바꾸지 않는다', () async {
      await started();
      final emitted = <TrackerState>[];
      final sub = tracker.states.listen(emitted.add);

      expect(await tracker.unpause(), isA<Ok<void>>());
      await pumpEventQueue();
      expect(emitted, isEmpty);

      await tracker.pause();
      final pausedAt = session().pausedAt;
      clock = t1;
      expect(await tracker.pause(), isA<Ok<void>>());
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted, hasLength(1));
      expect(session().pausedAt, pausedAt);
    });

    test('멈춤 중 점이 오면 위치 오류는 지우고 점은 버린다', () async {
      await started();
      await tracker.pause();
      positions.addError(Exception('gps lost'));
      await pumpEventQueue();
      expect((tracker.current as TrackerTracking).locationError, isNotNull);

      positions.add(_pos(37.5));
      await pumpEventQueue();

      final state = tracker.current as TrackerTracking;
      expect(state.locationError, isNull);
      expect(state.session.points, isEmpty);
      expect(state.session.isPaused, isTrue);
    });

    test('멈춤 중 오류 · resume 은 멈춤을 지킨다', () async {
      await started();
      await tracker.pause();
      positions.addError(Exception('gps lost'));
      await pumpEventQueue();
      expect(session().isPaused, isTrue);

      await tracker.resume();

      expect(session().isPaused, isTrue);
      expect(session().pausedAt, t0);
    });
  });

  group('저장소에 써 두기', () {
    test('start 는 세션 머리를 한 번 쓴다', () async {
      await started();
      await tracker.pendingWrites;

      final captured = verify(
        () => store.begin(captureAny(), _notice),
      ).captured;
      expect(captured, hasLength(1));
      final written = captured.single as WalkSession;
      expect(written.dogIds, ['d1']);
      expect(written.startedAt, t0);
      expect(written.points, isEmpty);
    });

    test('수락한 점은 seq 와 누적 거리로 begin 다음에 차례로 쓴다', () async {
      await started();
      positions.add(_pos(37.5));
      await pumpEventQueue();
      positions.add(_pos(37.6));
      await pumpEventQueue();
      await tracker.pendingWrites;

      verifyInOrder([
        () => store.begin(any(), any()),
        () => store.appendPoint(0, any(), 0),
        () => store.appendPoint(1, any(), 10),
      ]);
    });

    test('정책이 버린 점 · 멈춤 중 점은 쓰지 않는다', () async {
      await started();
      positions.add(_pos(37.5));
      await pumpEventQueue();
      positions.add(_pos(37.6, accuracy: 80));
      await pumpEventQueue();
      await tracker.pause();
      positions.add(_pos(37.7));
      await pumpEventQueue();
      await tracker.pendingWrites;

      verify(() => store.appendPoint(0, any(), 0)).called(1);
      verifyNever(() => store.appendPoint(1, any(), any()));
    });

    test('pause · unpause · stop 은 그 시점 세션으로 시간을 덮어쓴다', () async {
      await started();
      clock = t0.add(const Duration(minutes: 10));
      await tracker.pause();
      clock = t0.add(const Duration(minutes: 12));
      await tracker.unpause();
      clock = t1;
      await tracker.stop();
      await tracker.pendingWrites;

      final written = verify(
        () => store.updateTiming(captureAny()),
      ).captured.cast<WalkSession>();
      expect(written, hasLength(3));
      expect(written[0].pausedAt, t0.add(const Duration(minutes: 10)));
      expect(written[1].pausedAt, isNull);
      expect(written[1].pausedDuration, const Duration(minutes: 2));
      expect(written[2].endedAt, t1);
      expect(written[2].pausedAt, isNull);
    });

    test('finished 에서 clear 는 저장소를 비운다', () async {
      await started();
      await tracker.clear();
      await tracker.pendingWrites;
      verifyNever(() => store.clear());

      await tracker.stop();
      await tracker.clear();
      await tracker.pendingWrites;

      verify(() => store.clear()).called(1);
      expect(tracker.current, isA<TrackerIdle>());
    });

    test('쓰기가 던져도 추적은 이어 가고 뒤 쓰기도 순서대로 한다', () async {
      when(() => store.begin(any(), any())).thenThrow(Exception('disk full'));
      when(
        () => store.appendPoint(0, any(), any()),
      ).thenAnswer((_) async => throw Exception('disk full'));

      await started();
      positions.add(_pos(37.5));
      await pumpEventQueue();
      positions.add(_pos(37.6));
      await pumpEventQueue();
      await tracker.pendingWrites;

      expect(session().points, hasLength(2));
      verifyInOrder([
        () => store.begin(any(), any()),
        () => store.appendPoint(0, any(), 0),
        () => store.appendPoint(1, any(), 10),
      ]);
    });

    test('느린 begin 이 끝나기 전에는 점을 쓰지 않는다', () async {
      final gate = Completer<void>();
      when(() => store.begin(any(), any())).thenAnswer((_) => gate.future);

      await started();
      positions.add(_pos(37.5));
      await pumpEventQueue();
      verifyNever(() => store.appendPoint(any(), any(), any()));

      gate.complete();
      await tracker.pendingWrites;
      verify(() => store.appendPoint(0, any(), 0)).called(1);
    });
  });

  group('restore', () {
    final point1 = WalkTrackPoint(
      point: const GeoPoint(lat: 37.5, lng: 127),
      recordedAt: t0,
      accuracy: 5,
    );
    final point2 = WalkTrackPoint(
      point: const GeoPoint(lat: 37.6, lng: 127),
      recordedAt: t0,
      accuracy: 5,
    );
    WalkSession saved({DateTime? pausedAt, DateTime? endedAt}) => WalkSession(
      dogIds: const ['d1'],
      startedAt: t0,
      points: [point1, point2],
      distanceMeters: 20,
      pausedDuration: const Duration(minutes: 1),
      pausedAt: pausedAt,
      endedAt: endedAt,
    );
    void loads(WalkSession session) => when(() => store.load()).thenAnswer(
      (_) async => ActiveWalkSnapshot(session: session, notice: _notice),
    );

    test('남은 세션이 없으면 idle 그대로이고 구독하지 않는다', () async {
      await tracker.restore();

      expect(tracker.current, isA<TrackerIdle>());
      verifyNever(() => gateway.positionStream(any()));
    });

    test('끝난 세션이면 finished 로 되살리고 구독하지 않는다', () async {
      final ended = saved(endedAt: t1);
      loads(ended);

      await tracker.restore();

      expect((tracker.current as TrackerFinished).session, ended);
      verifyNever(() => gateway.positionStream(any()));
    });

    test('진행 중 세션이면 tracking 으로 되살리고 점을 이어 쓴다', () async {
      final active = saved();
      loads(active);

      await tracker.restore();

      final state = tracker.current as TrackerTracking;
      expect(state.session, active);
      expect(state.locationError, isNull);
      expect(positions.hasListener, isTrue);

      positions.add(_pos(37.7));
      await pumpEventQueue();
      await tracker.pendingWrites;

      // 죽어 있던 동안도 걸은 것으로 센다: 첫 새 점의 거리를 그대로 더한다.
      expect(session().points, hasLength(3));
      expect(session().distanceMeters, 30);
      verify(() => store.appendPoint(2, any(), 30)).called(1);
      verifyNever(() => store.begin(any(), any()));
    });

    test('멈춘 채 저장된 세션은 멈춤 그대로 되살리고 점을 버린다', () async {
      final paused = saved(pausedAt: t0.add(const Duration(minutes: 5)));
      loads(paused);

      await tracker.restore();
      clock = t1;

      expect(session().isPaused, isTrue);
      expect(session().pausedAt, t0.add(const Duration(minutes: 5)));
      // 죽어 있던 동안도 멈춤으로 센다: 걸은 시간은 1 분 + 4 분 뒤 멈춤.
      expect(session().elapsedAt(clock), const Duration(minutes: 4));

      positions.add(_pos(37.7));
      await pumpEventQueue();
      await tracker.pendingWrites;

      expect(session().points, hasLength(2));
      verifyNever(() => store.appendPoint(any(), any(), any()));
    });

    test('위치 서비스가 꺼져 있으면 세션을 지킨 채 오류를 싣는다', () async {
      when(
        () => gateway.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);
      final active = saved();
      loads(active);

      await tracker.restore();

      final state = tracker.current as TrackerTracking;
      expect(state.session, active);
      expect(
        state.locationError?.failureCode,
        FailureCode.locationServiceDisabled,
      );
      verifyNever(() => gateway.positionStream(any()));

      // 알림 문구를 기억해 resume 으로 다시 받을 수 있다.
      when(
        () => gateway.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      expect(await tracker.resume(), isA<Ok<void>>());
      expect(positions.hasListener, isTrue);
    });

    test('load 가 던지면 idle 그대로다', () async {
      when(() => store.load()).thenThrow(Exception('corrupt'));

      await tracker.restore();

      expect(tracker.current, isA<TrackerIdle>());
    });

    test('이미 시작했으면 아무것도 하지 않는다', () async {
      await started();
      loads(saved());

      await tracker.restore();

      expect(session().points, isEmpty);
      verifyNever(() => store.load());
    });
  });

  test('설정 열기는 앱 설정 · 위치 설정을 게이트웨이에 맡긴다', () async {
    when(() => gateway.openAppSettings()).thenAnswer((_) async => true);
    when(() => gateway.openLocationSettings()).thenAnswer((_) async => true);

    await tracker.openAppSettings();
    await tracker.openLocationSettings();

    verify(() => gateway.openAppSettings()).called(1);
    verify(() => gateway.openLocationSettings()).called(1);
  });
}
