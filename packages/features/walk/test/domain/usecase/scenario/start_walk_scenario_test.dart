import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fakes.dart';

void main() {
  late MockWalkTracker tracker;
  late StartWalkScenario scenario;
  const notice = TrackingNotice(title: '산책 중', text: '기록하고 있어요');

  setUpAll(registerFallbacks);

  setUp(() {
    tracker = MockWalkTracker();
    scenario = StartWalkScenario(tracker);
    when(() => tracker.current).thenReturn(const TrackerState.idle());
    when(
      () => tracker.start(
        dogIds: any(named: 'dogIds'),
        notice: any(named: 'notice'),
      ),
    ).thenAnswer((_) async => const Ok(null));
  });

  test('추적 중이면 walkTrackingAlreadyActive', () async {
    when(() => tracker.current).thenReturn(
      TrackerState.tracking(
        WalkSession(
          dogIds: const ['d1'],
          startedAt: t0,
          points: const [],
          distanceMeters: 0,
        ),
      ),
    );

    final result = await scenario(dogIds: const ['d1'], notice: notice);

    expect(
      (result as Err<void>).failure.failureCode,
      FailureCode.walkTrackingAlreadyActive,
    );
  });

  test('반려견이 없으면 walkDogRequired', () async {
    final result = await scenario(dogIds: const [], notice: notice);

    expect(
      (result as Err<void>).failure.failureCode,
      FailureCode.walkDogRequired,
    );
  });

  test('아니면 tracker 를 시작한다', () async {
    final result = await scenario(dogIds: const ['d1'], notice: notice);

    expect(result, isA<Ok<void>>());
    verify(() => tracker.start(dogIds: const ['d1'], notice: notice)).called(1);
  });
}
