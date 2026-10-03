import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';

void main() {
  late MockWalkUseCase useCase;

  setUp(() => useCase = MockWalkUseCase());

  blocTest<DogListCubit, DogListState>(
    '스트림이 강아지 2마리를 내면 loading 뒤 loaded 가 된다',
    setUp: () => when(
      () => useCase.watchDogs(),
    ).thenAnswer((_) => Stream.value(Ok([dog('1'), dog('2')]))),
    build: () => DogListCubit(useCase),
    act: (cubit) => cubit.start(),
    expect: () => [
      const DogListState.loading(),
      DogListState.loaded([dog('1'), dog('2')]),
    ],
  );

  blocTest<DogListCubit, DogListState>(
    '스트림이 Err 를 내면 failure 가 된다',
    setUp: () => when(
      () => useCase.watchDogs(),
    ).thenAnswer((_) => Stream.value(const Err(Failure.unknown()))),
    build: () => DogListCubit(useCase),
    act: (cubit) => cubit.start(),
    expect: () => [
      const DogListState.loading(),
      const DogListState.failure(Failure.unknown()),
    ],
  );

  test('닫힌 뒤에 온 스트림 값은 상태를 내지 않는다', () async {
    final controller = StreamController<Result<List<Dog>>>();
    when(() => useCase.watchDogs()).thenAnswer((_) => controller.stream);
    final cubit = DogListCubit(useCase);
    await cubit.start();
    await cubit.close();

    controller.add(Ok([dog('1')]));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const DogListState.loading());
    expect(controller.hasListener, isFalse);
    await controller.close();
  });
}
