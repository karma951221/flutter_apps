import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';
import 'package:walk/domain/transit/repository/recent_points.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/find_transit_routes.dart';
import 'package:walk/presentation/transit/cubit/transit_cubit.dart';
import 'package:walk/presentation/transit/cubit/transit_state.dart';

class _MockFind extends Mock implements FindTransitRoutes {}

class _MockPlaceSource extends Mock implements PlaceSource {}

class _MockRecent extends Mock implements RecentPoints {}

const _a = TransitPoint(
  lat: 37.5,
  lng: 127.0,
  label: 'A',
  source: TransitPointSource.station,
);
const _b = TransitPoint(
  lat: 37.4,
  lng: 127.1,
  label: 'B',
  source: TransitPointSource.address,
);
const _c = TransitPoint(
  lat: 37.3,
  lng: 127.2,
  label: 'C',
  source: TransitPointSource.address,
);

TransitRoutesResult _result() => TransitRoutesResult(
  paths: const [],
  fetchedAt: DateTime(2026, 11, 17),
  fromCache: false,
);

void main() {
  late _MockFind find;
  late _MockPlaceSource place;
  late _MockRecent recent;
  late TransitCubit cubit;

  setUp(() {
    registerFallbackValue(_a);
    find = _MockFind();
    place = _MockPlaceSource();
    recent = _MockRecent();
    when(() => recent.add(any())).thenAnswer((_) async {});
    when(
      () => find(any(), any(), refresh: any(named: 'refresh')),
    ).thenAnswer((_) async => _result());
    cubit = TransitCubit(find, place, recent);
  });

  tearDown(() => cubit.close());

  test('both filled triggers find', () async {
    await cubit.setFrom(_a);
    verifyNever(() => find(any(), any(), refresh: any(named: 'refresh')));
    await cubit.setTo(_b);
    await pumpEventQueue();
    verify(() => find(_a, _b, refresh: false)).called(1);
    expect(cubit.state.status, isA<TransitLoaded>());
  });

  test('fillEmpty fills from then to then replaces to', () async {
    await cubit.fillEmpty(_a);
    expect(cubit.state.from, _a);
    expect(cubit.state.to, isNull);
    await cubit.fillEmpty(_b);
    expect(cubit.state.to, _b);
    await cubit.fillEmpty(_c);
    expect(cubit.state.from, _a);
    expect(cubit.state.to, _c);
  });

  test('swap re-queries', () async {
    await cubit.setFrom(_a);
    await cubit.setTo(_b);
    await pumpEventQueue();
    cubit.swap();
    await pumpEventQueue();
    expect(cubit.state.from, _b);
    expect(cubit.state.to, _a);
    verify(() => find(_b, _a, refresh: false)).called(1);
  });

  test('refresh passes refresh flag', () async {
    await cubit.setFrom(_a);
    await cubit.setTo(_b);
    await pumpEventQueue();
    cubit.refresh();
    await pumpEventQueue();
    verify(() => find(_a, _b, refresh: true)).called(1);
  });

  test('stale response ignored', () async {
    final first = Completer<TransitRoutesResult>();
    final secondResult = _result();
    when(
      () => find(_a, _b, refresh: any(named: 'refresh')),
    ).thenAnswer((_) => first.future);
    when(
      () => find(_a, _c, refresh: any(named: 'refresh')),
    ).thenAnswer((_) async => secondResult);
    await cubit.setFrom(_a);
    await cubit.setTo(_b);
    await cubit.setTo(_c);
    await pumpEventQueue();
    expect((cubit.state.status as TransitLoaded).result, secondResult);
    first.completeError(const TransitFailure.network());
    await pumpEventQueue();
    expect((cubit.state.status as TransitLoaded).result, secondResult);
  });

  test('location failure sets locationFailed, from stays null', () async {
    when(() => place.current()).thenAnswer((_) async => null);
    await cubit.start();
    expect(cubit.state.locationFailed, isTrue);
    expect(cubit.state.locating, isFalse);
    expect(cubit.state.from, isNull);
  });

  test('location success fills from with currentLocation', () async {
    when(
      () => place.current(),
    ).thenAnswer((_) async => const EntryLocation(lat: 37.1, lng: 127.1));
    await cubit.start();
    expect(cubit.state.from?.source, TransitPointSource.currentLocation);
    expect(cubit.state.from?.lat, 37.1);
    expect(cubit.state.locationFailed, isFalse);
  });

  test('location exception counts as failure', () async {
    when(() => place.current()).thenThrow(Exception('boom'));
    await cubit.start();
    expect(cubit.state.locationFailed, isTrue);
  });

  test('failure state carries TransitFailure', () async {
    when(
      () => find(any(), any(), refresh: any(named: 'refresh')),
    ).thenThrow(const TransitFailure.noRoute());
    await cubit.setFrom(_a);
    await cubit.setTo(_b);
    await pumpEventQueue();
    final status = cubit.state.status as TransitFailed;
    expect(status.failure, isA<TransitNoRoute>());
  });

  test('unknown exception becomes server failure', () async {
    when(
      () => find(any(), any(), refresh: any(named: 'refresh')),
    ).thenThrow(StateError('x'));
    await cubit.setFrom(_a);
    await cubit.setTo(_b);
    await pumpEventQueue();
    final failure = (cubit.state.status as TransitFailed).failure;
    expect(failure, const TransitFailure.server('StateError'));
  });

  test('recent added except currentLocation', () async {
    when(
      () => place.current(),
    ).thenAnswer((_) async => const EntryLocation(lat: 37.1, lng: 127.1));
    await cubit.start();
    verifyNever(() => recent.add(any()));
    await cubit.setTo(_b);
    verify(() => recent.add(_b)).called(1);
  });
}
