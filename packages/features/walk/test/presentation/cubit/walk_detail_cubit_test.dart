import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';

void main() {
  late MockWalkUseCase useCase;
  final track = [trackPoint(37.5), trackPoint(37.501)];

  setUp(() {
    useCase = MockWalkUseCase();
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => Ok(walk()));
    when(() => useCase.getWalkTrack('w1')).thenAnswer((_) async => Ok(track));
  });

  blocTest<WalkDetailCubit, WalkDetailState>(
    'load 가 walk 와 track 을 함께 읽는다',
    build: () => WalkDetailCubit(useCase),
    act: (cubit) => cubit.load('w1'),
    expect: () => [
      const WalkDetailState.loading(),
      WalkDetailState.loaded(walk: walk(), track: track),
    ],
    verify: (_) {
      verify(() => useCase.getWalk('w1')).called(1);
      verify(() => useCase.getWalkTrack('w1')).called(1);
    },
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '없는 산책이면 failure walkNotFound',
    setUp: () => when(
      () => useCase.getWalk('w1'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => WalkDetailCubit(useCase),
    act: (cubit) => cubit.load('w1'),
    expect: () => [
      const WalkDetailState.loading(),
      isA<WalkDetailFailure>().having(
        (s) => s.failure.failureCode,
        'failureCode',
        FailureCode.walkNotFound,
      ),
    ],
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '읽기가 실패하면 failure',
    setUp: () => when(
      () => useCase.getWalkTrack('w1'),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => WalkDetailCubit(useCase),
    act: (cubit) => cubit.load('w1'),
    expect: () => [
      const WalkDetailState.loading(),
      const WalkDetailState.failure(Failure.network()),
    ],
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '다시 읽을 때는 loading 으로 화면을 비우지 않는다',
    build: () => WalkDetailCubit(useCase),
    act: (cubit) async {
      await cubit.load('w1');
      await cubit.load('w1');
    },
    expect: () => [
      const WalkDetailState.loading(),
      WalkDetailState.loaded(walk: walk(), track: track),
    ],
    verify: (_) => verify(() => useCase.getWalk('w1')).called(2),
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '삭제 → deleting → deleted',
    setUp: () => when(
      () => useCase.deleteWalk('w1'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => WalkDetailCubit(useCase),
    act: (cubit) async {
      await cubit.load('w1');
      await cubit.delete();
    },
    skip: 2,
    expect: () => [
      WalkDetailState.deleting(walk: walk(), track: track),
      const WalkDetailState.deleted(),
    ],
  );

  blocTest<WalkDetailCubit, WalkDetailState>(
    '삭제 실패 → loaded 에 failure',
    setUp: () => when(
      () => useCase.deleteWalk('w1'),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => WalkDetailCubit(useCase),
    act: (cubit) async {
      await cubit.load('w1');
      await cubit.delete();
    },
    skip: 2,
    expect: () => [
      WalkDetailState.deleting(walk: walk(), track: track),
      WalkDetailState.loaded(
        walk: walk(),
        track: track,
        failure: const Failure.network(),
      ),
    ],
  );
}
