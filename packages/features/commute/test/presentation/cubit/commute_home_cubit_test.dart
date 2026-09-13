import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommuteUseCase extends Mock implements CommuteUseCase {}

const _destination = Station(
  id: '0222',
  name: '강남',
  lines: ['2'],
  location: GeoPoint(lat: 37.4979, lng: 127.0276),
);

CommuteResult _result(CommuteDirection direction) => CommuteResult(
  direction: direction,
  origin: const Origin.currentLocation(GeoPoint(lat: 37.5, lng: 127)),
  destination: _destination,
  routes: const [],
  searchedAt: DateTime.utc(2026, 9, 13),
);

void main() {
  late _MockCommuteUseCase useCase;

  setUpAll(() => registerFallbackValue(CommuteDirection.toWork));
  setUp(() => useCase = _MockCommuteUseCase());

  blocTest<CommuteHomeCubit, CommuteHomeState>(
    '기본 출근 방향을 검색해 결과를 담는다',
    build: () {
      when(
        () => useCase.searchCommute(CommuteDirection.toWork),
      ).thenAnswer((_) async => Ok(_result(CommuteDirection.toWork)));
      return CommuteHomeCubit(useCase);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const CommuteHomeState.loading(CommuteDirection.toWork),
      CommuteHomeState.loaded(
        CommuteDirection.toWork,
        _result(CommuteDirection.toWork),
      ),
    ],
  );

  blocTest<CommuteHomeCubit, CommuteHomeState>(
    '방향을 바꾸면 즉시 퇴근 경로를 검색한다',
    build: () {
      when(
        () => useCase.searchCommute(CommuteDirection.toHome),
      ).thenAnswer((_) async => Ok(_result(CommuteDirection.toHome)));
      return CommuteHomeCubit(useCase);
    },
    act: (cubit) => cubit.setDirection(CommuteDirection.toHome),
    expect: () => [
      const CommuteHomeState.loading(CommuteDirection.toHome),
      CommuteHomeState.loaded(
        CommuteDirection.toHome,
        _result(CommuteDirection.toHome),
      ),
    ],
    verify: (_) =>
        verify(() => useCase.searchCommute(CommuteDirection.toHome)).called(1),
  );

  blocTest<CommuteHomeCubit, CommuteHomeState>(
    '검색 실패에도 현재 방향을 보존한다',
    build: () {
      when(
        () => useCase.searchCommute(CommuteDirection.toWork),
      ).thenAnswer((_) async => const Err(Failure.network()));
      return CommuteHomeCubit(useCase);
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      CommuteHomeState.loading(CommuteDirection.toWork),
      CommuteHomeState.failure(CommuteDirection.toWork, Failure.network()),
    ],
  );

  test('앞 방향의 늦은 응답은 새 방향 결과를 덮지 않는다', () async {
    final toWork = Completer<Result<CommuteResult>>();
    when(
      () => useCase.searchCommute(CommuteDirection.toWork),
    ).thenAnswer((_) => toWork.future);
    when(
      () => useCase.searchCommute(CommuteDirection.toHome),
    ).thenAnswer((_) async => Ok(_result(CommuteDirection.toHome)));
    final cubit = CommuteHomeCubit(useCase);
    addTearDown(cubit.close);

    final first = cubit.load();
    await cubit.setDirection(CommuteDirection.toHome);
    toWork.complete(Ok(_result(CommuteDirection.toWork)));
    await first;

    expect(
      cubit.state,
      CommuteHomeState.loaded(
        CommuteDirection.toHome,
        _result(CommuteDirection.toHome),
      ),
    );
  });
}
