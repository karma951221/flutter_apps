import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/commute/commute_failure.dart';
import 'package:walk/domain/commute/entity/catch_verdict.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/entity/commute_result.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';
import 'package:walk/domain/commute/repository/address_search.dart';
import 'package:walk/domain/commute/usecase/commute_use_case.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/presentation/commute/cubit/commute_cubit.dart';
import 'package:walk/presentation/commute/cubit/commute_state.dart';

class _MockUseCase extends Mock implements CommuteUseCase {}

class _MockPlaceSource extends Mock implements PlaceSource {}

class _MockSearch extends Mock implements AddressSearch {}

class _FixedClock extends Clock {
  _FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

const _home = Place(kind: PlaceKind.home, lat: 37.5, lng: 127.0, label: '집');
const _work = Place(kind: PlaceKind.work, lat: 37.4, lng: 127.1, label: '회사');

const _route = TransitRoute(
  totalMinutes: 30,
  transferCount: 0,
  legs: [WalkLeg(minutes: 5)],
);

final _result = CommuteResult(
  direction: CommuteDirection.toWork,
  route: _route,
  alternatives: const [],
  arrivals: const [],
  realtime: RealtimeStatus.unavailable,
  verdict: const CatchVerdict.unknown(),
  eta: DateTime(2026, 10, 21, 8, 40),
  etaFromRealtime: false,
  queriedAt: DateTime(2026, 10, 21, 8),
);

void main() {
  late _MockUseCase useCase;
  late _MockPlaceSource source;
  late _MockSearch search;
  late _FixedClock clock;

  setUpAll(() {
    registerFallbackValue(CommuteDirection.toWork);
    registerFallbackValue(_home);
    registerFallbackValue(_route);
    registerFallbackValue(_result);
  });

  setUp(() {
    useCase = _MockUseCase();
    source = _MockPlaceSource();
    search = _MockSearch();
    clock = _FixedClock(DateTime(2026, 10, 21, 8));
    when(() => useCase.place(PlaceKind.home)).thenReturn(_home);
    when(() => useCase.place(PlaceKind.work)).thenReturn(_work);
    when(() => useCase.savePlace(any())).thenAnswer((_) async {});
  });

  CommuteCubit build() => CommuteCubit(useCase, source, search, clock);

  test('initial direction follows the clock and reads saved places', () {
    final morning = build();
    expect(morning.state.direction, CommuteDirection.toWork);
    expect(morning.state.home, _home);
    expect(morning.state.work, _work);
    expect(morning.state.status, const CommuteStatus.idle());
    clock.value = DateTime(2026, 10, 21, 13);
    final evening = build();
    expect(evening.state.direction, CommuteDirection.toHome);
    morning.close();
    evening.close();
  });

  test('query emits loading then loaded', () async {
    when(() => useCase.query(any())).thenAnswer((_) async => _result);
    final cubit = build();
    final states = <CommuteStatus>[];
    final sub = cubit.stream.listen((s) => states.add(s.status));
    await cubit.query();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(states, [
      const CommuteStatus.loading(),
      CommuteStatus.loaded(_result),
    ]);
    await cubit.close();
  });

  test('CommuteFailure becomes failure', () async {
    when(() => useCase.query(any())).thenThrow(const CommuteFailure.noRoute());
    final cubit = build();
    await cubit.query();
    expect(
      cubit.state.status,
      const CommuteStatus.failure(CommuteFailure.noRoute()),
    );
    await cubit.close();
  });

  test('other exceptions are wrapped as server failure', () async {
    when(() => useCase.query(any())).thenThrow(StateError('boom'));
    final cubit = build();
    await cubit.query();
    expect(
      cubit.state.status,
      const CommuteStatus.failure(CommuteFailure.server('')),
    );
    await cubit.close();
  });

  test('ignores query while loading', () async {
    final completer = Completer<CommuteResult>();
    when(() => useCase.query(any())).thenAnswer((_) => completer.future);
    final cubit = build();
    final first = cubit.query();
    await cubit.query();
    completer.complete(_result);
    await first;
    verify(() => useCase.query(any())).called(1);
    await cubit.close();
  });

  test('failure then retry calls the use case again', () async {
    var n = 0;
    when(() => useCase.query(any())).thenAnswer((_) async {
      if (n++ == 0) throw const CommuteFailure.network();
      return _result;
    });
    final cubit = build();
    await cubit.query();
    expect(
      cubit.state.status,
      const CommuteStatus.failure(CommuteFailure.network()),
    );
    await cubit.query();
    expect(cubit.state.status, CommuteStatus.loaded(_result));
    verify(() => useCase.query(any())).called(2);
    await cubit.close();
  });

  test('setDirection clears result', () async {
    when(() => useCase.query(any())).thenAnswer((_) async => _result);
    final cubit = build();
    await cubit.query();
    cubit.setDirection(CommuteDirection.toHome);
    expect(cubit.state.direction, CommuteDirection.toHome);
    expect(cubit.state.status, const CommuteStatus.idle());
    await cubit.close();
  });

  test('selectRoute replaces the loaded result', () async {
    when(() => useCase.query(any())).thenAnswer((_) async => _result);
    final next = _result.copyWith(etaFromRealtime: true);
    when(() => useCase.selectRoute(any(), any())).thenAnswer((_) async => next);
    final cubit = build();
    await cubit.selectRoute(_route);
    verifyNever(() => useCase.selectRoute(any(), any()));
    await cubit.query();
    await cubit.selectRoute(_route);
    expect(cubit.state.status, CommuteStatus.loaded(next));
    await cubit.close();
  });

  test('selectRoute failure emits failure', () async {
    when(() => useCase.query(any())).thenAnswer((_) async => _result);
    when(
      () => useCase.selectRoute(any(), any()),
    ).thenThrow(const CommuteFailure.network());
    final cubit = build();
    await cubit.query();
    await cubit.selectRoute(_route);
    expect(
      cubit.state.status,
      const CommuteStatus.failure(CommuteFailure.network()),
    );
    expect(cubit.state.home, _home);
    await cubit.close();
  });

  test('useCurrentLocation null -> false and no save', () async {
    when(() => source.current()).thenAnswer((_) async => null);
    final cubit = build();
    expect(await cubit.useCurrentLocation(PlaceKind.home), isFalse);
    verifyNever(() => useCase.savePlace(any()));
    expect(cubit.state.locating, isFalse);
    await cubit.close();
  });

  test('useCurrentLocation saves with name or coordinate label', () async {
    when(() => source.current()).thenAnswer(
      (_) async => const EntryLocation(placeName: '강남역', lat: 1, lng: 2),
    );
    final cubit = build();
    expect(await cubit.useCurrentLocation(PlaceKind.home), isTrue);
    expect(
      cubit.state.home,
      const Place(kind: PlaceKind.home, lat: 1, lng: 2, label: '강남역'),
    );
    when(
      () => source.current(),
    ).thenAnswer((_) async => const EntryLocation(lat: 37.123456, lng: 127.5));
    expect(await cubit.useCurrentLocation(PlaceKind.work), isTrue);
    expect(cubit.state.work?.label, '37.12346, 127.50000');
    expect(cubit.state.locating, isFalse);
    await cubit.close();
  });

  test('choosePlace saves and updates state', () async {
    final cubit = build();
    await cubit.choosePlace(
      PlaceKind.work,
      const PlaceCandidate(lat: 3, lng: 4, label: '판교'),
    );
    const expected = Place(kind: PlaceKind.work, lat: 3, lng: 4, label: '판교');
    verify(() => useCase.savePlace(expected)).called(1);
    expect(cubit.state.work, expected);
    await cubit.close();
  });

  test('searchAddress delegates', () async {
    const c = PlaceCandidate(lat: 1, lng: 2, label: 'x');
    when(() => search.search('q')).thenAnswer((_) async => [c]);
    final cubit = build();
    expect(await cubit.searchAddress('q'), [c]);
    await cubit.close();
  });
}
