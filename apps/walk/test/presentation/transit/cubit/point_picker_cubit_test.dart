import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/commute/repository/address_search.dart';
import 'package:walk/domain/transit/entity/station_hit.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/search_stations.dart';
import 'package:walk/domain/transit/usecase/transit_point_suggestions.dart';
import 'package:walk/presentation/transit/cubit/point_picker_cubit.dart';

class _MockStations extends Mock implements SearchStations {}

class _MockAddress extends Mock implements AddressSearch {}

class _MockSuggestions extends Mock implements TransitPointSuggestions {}

class _MockKeyStore extends Mock implements TransitKeyStore {}

const _hit = StationHit(
  name: '서울역',
  kind: StationKind.subway,
  lat: 37.55,
  lng: 126.97,
  detail: '1호선',
);

void main() {
  late _MockStations stations;
  late _MockAddress address;
  late _MockSuggestions suggestions;
  late _MockKeyStore keyStore;
  late StreamController<void> keyChanges;

  setUp(() {
    keyStore = _MockKeyStore();
    keyChanges = StreamController<void>.broadcast(sync: true);
    when(() => keyStore.changes).thenAnswer((_) => keyChanges.stream);
    stations = _MockStations();
    address = _MockAddress();
    suggestions = _MockSuggestions();
    when(() => stations(any())).thenAnswer((_) async => [_hit]);
    when(() => address.search(any())).thenAnswer(
      (_) async => const [PlaceCandidate(lat: 1, lng: 2, label: '주소')],
    );
    when(
      () => suggestions.load(),
    ).thenAnswer((_) async => const TransitSuggestions());
  });

  PointPickerCubit make() =>
      PointPickerCubit(stations, address, suggestions, keyStore);

  test('load fills suggestions', () async {
    final cubit = make();
    await cubit.load();
    expect(cubit.state.suggestions, isNotNull);
    await cubit.close();
  });

  test('typing within 500ms calls search once', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서울');
      async.elapse(const Duration(milliseconds: 300));
      cubit.queryChanged('서울역');
      async.elapse(const Duration(milliseconds: 499));
      verifyNever(() => stations(any()));
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      verify(() => stations('서울역')).called(1);
      expect(cubit.state.stations, [_hit]);
      expect(cubit.state.searching, isFalse);
      cubit.close();
    });
  });

  test('composing input searches after the longer 900ms debounce', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서울', composing: true);
      async.elapse(const Duration(milliseconds: 899));
      verifyNever(() => stations(any()));
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      verify(() => stations('서울')).called(1);
      async.elapse(const Duration(seconds: 2));
      verifyNoMoreInteractions(stations);
      cubit.close();
    });
  });

  test('composing then committed restarts the 500ms debounce once', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서울', composing: true);
      async.elapse(const Duration(milliseconds: 300));
      cubit.queryChanged('서울', composing: false);
      async.elapse(const Duration(milliseconds: 499));
      verifyNever(() => stations(any()));
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      verify(() => stations('서울')).called(1);
      async.elapse(const Duration(seconds: 2));
      verifyNoMoreInteractions(stations);
      cubit.close();
    });
  });

  test('submitted searches stations now and not addresses', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서울역', composing: true);
      cubit.submitted('서울역');
      async.flushMicrotasks();
      verify(() => stations('서울역')).called(1);
      expect(cubit.state.stations, [_hit]);
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      verifyNoMoreInteractions(stations);
      verifyNever(() => address.search(any()));
      cubit.close();
    });
  });

  test('submitted with short text does not search', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.submitted('서');
      async.elapse(const Duration(seconds: 2));
      verifyNever(() => stations(any()));
      cubit.close();
    });
  });

  group('key change', () {
    void failThenChange(FakeAsync async, PointPickerCubit cubit, Object e) {
      when(() => stations(any())).thenAnswer((_) async => throw e);
      cubit.queryChanged('서울역');
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      when(() => stations(any())).thenAnswer((_) async => [_hit]);
      keyChanges.add(null);
      async.flushMicrotasks();
    }

    test('re-runs station search after missingKey', () {
      fakeAsync((async) {
        final cubit = make();
        failThenChange(async, cubit, const TransitFailure.missingKey());
        verify(() => stations('서울역')).called(2);
        expect(cubit.state.stationFailure, isNull);
        expect(cubit.state.stations, [_hit]);
        cubit.close();
      });
    });

    test('re-runs station search after keyRejected', () {
      fakeAsync((async) {
        final cubit = make();
        failThenChange(async, cubit, const TransitFailure.keyRejected('x'));
        expect(cubit.state.stations, [_hit]);
        cubit.close();
      });
    });

    test('ignored after other failures', () {
      fakeAsync((async) {
        final cubit = make();
        failThenChange(async, cubit, const TransitFailure.network());
        verify(() => stations('서울역')).called(1);
        expect(cubit.state.stationFailure, const TransitFailure.network());
        cubit.close();
      });
    });

    test('close cancels the subscription', () async {
      final cubit = make();
      await cubit.close();
      expect(keyChanges.hasListener, isFalse);
    });
  });

  test('1 char does not call', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서');
      async.elapse(const Duration(seconds: 2));
      verifyNever(() => stations(any()));
      cubit.close();
    });
  });

  test('address search only on demand', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서울역');
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      verifyNever(() => address.search(any()));
      cubit.searchAddress();
      async.flushMicrotasks();
      verify(() => address.search('서울역')).called(1);
      expect(cubit.state.addresses, hasLength(1));
      expect(cubit.state.addressSearching, isFalse);
      cubit.close();
    });
  });

  test('close cancels pending debounce', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서울역');
      cubit.close();
      async.elapse(const Duration(seconds: 2));
      verifyNever(() => stations(any()));
    });
  });

  test('station failure is surfaced and cleared on new query', () {
    fakeAsync((async) {
      when(
        () => stations(any()),
      ).thenAnswer((_) async => throw const TransitFailure.keyRejected('bad'));
      final cubit = make();
      cubit.queryChanged('서울역');
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(cubit.state.stationFailure, isA<TransitKeyRejected>());
      expect(cubit.state.searching, isFalse);
      cubit.queryChanged('서울');
      expect(cubit.state.stationFailure, isNull);
      cubit.close();
    });
  });

  test('unknown station exception becomes server failure', () {
    fakeAsync((async) {
      when(
        () => stations(any()),
      ).thenAnswer((_) async => throw StateError('x'));
      final cubit = make();
      cubit.queryChanged('서울역');
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(
        cubit.state.stationFailure,
        const TransitFailure.unexpected('StateError: Bad state: x'),
      );
      cubit.close();
    });
  });

  test('stale station result dropped when query changes mid-flight', () {
    fakeAsync((async) {
      final first = Completer<List<StationHit>>();
      when(() => stations('서울역')).thenAnswer((_) => first.future);
      final cubit = make();
      cubit.queryChanged('서울역');
      async.elapse(const Duration(seconds: 1));
      cubit.queryChanged('서');
      first.complete([_hit]);
      async.flushMicrotasks();
      expect(cubit.state.stations, isEmpty);
      expect(cubit.state.query, '서');
      cubit.close();
    });
  });

  test('addresses cleared on query change', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서울역');
      cubit.searchAddress();
      async.flushMicrotasks();
      expect(cubit.state.addresses, hasLength(1));
      cubit.queryChanged('서울역 근처');
      expect(cubit.state.addresses, isEmpty);
      cubit.close();
    });
  });

  tearDown(() => keyChanges.close());
}
