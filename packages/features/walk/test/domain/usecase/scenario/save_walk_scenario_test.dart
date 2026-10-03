import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fakes.dart';

void main() {
  late MockWalkRepository walks;
  late MockDogRepository dogs;
  late MockWalkTracker tracker;
  late MockIdGenerator ids;
  late SaveWalkScenario scenario;
  final now = DateTime(2026, 10, 3, 10);

  setUpAll(registerFallbacks);

  setUp(() {
    walks = MockWalkRepository();
    dogs = MockDogRepository();
    tracker = MockWalkTracker();
    ids = MockIdGenerator();
    scenario = SaveWalkScenario(walks, dogs, tracker, ids, () => now);
    when(
      () => dogs.getAll(),
    ).thenAnswer((_) async => Ok([dog('d1'), dog('d2')]));
    when(() => tracker.clear()).thenAnswer((_) async {});
    when(
      () => walks.insert(any(), any()),
    ).thenAnswer((_) async => const Ok(null));
    var n = 0;
    when(() => ids.newId()).thenAnswer((_) => 'id${n++}');
  });

  WalkDraft draft({List<String> dogIds = const ['d1']}) => WalkDraft(
    startedAt: t0,
    endedAt: t1,
    distanceMeters: 1200,
    points: [trackPoint(37), trackPoint(37.01)],
    dogIds: dogIds,
    photoPaths: const ['photos/a.jpg', 'photos/b.jpg'],
  );

  test('반려견이 없으면 walkDogRequired', () async {
    final result = await scenario(draft(dogIds: const []));

    expect(
      (result as Err<Walk>).failure.failureCode,
      FailureCode.walkDogRequired,
    );
    verifyNever(() => walks.insert(any(), any()));
  });

  test('고른 반려견이 모두 삭제된 상태면 walkDogRequired', () async {
    final result = await scenario(draft(dogIds: const ['gone']));

    expect(
      (result as Err<Walk>).failure.failureCode,
      FailureCode.walkDogRequired,
    );
    verifyNever(() => walks.insert(any(), any()));
    verifyNever(() => tracker.clear());
  });

  test('id · 시각 · 프리뷰를 채워 저장하고 tracker 를 비운다', () async {
    final result = await scenario(draft());

    final saved = (result as Ok<Walk>).value;
    expect(saved.id, 'id0');
    expect(saved.duration, const Duration(minutes: 30));
    expect(saved.createdAt, now);
    expect(saved.updatedAt, now);
    expect(saved.dogs.map((d) => d.id), ['d1']);
    expect(saved.previewPoints.length, 2);
    expect(saved.photos.map((p) => (p.id, p.position)), [
      ('id1', 0),
      ('id2', 1),
    ]);
    verify(() => walks.insert(saved, any())).called(1);
    verify(() => tracker.clear()).called(1);
  });

  test('저장 실패면 tracker 를 비우지 않는다', () async {
    when(
      () => walks.insert(any(), any()),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario(draft());

    expect(result, isA<Err<Walk>>());
    verifyNever(() => tracker.clear());
  });
}
