import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/commute/repository/address_search.dart';
import 'package:walk/domain/transit/entity/station_hit.dart';
import 'package:walk/domain/transit/usecase/search_stations.dart';
import 'package:walk/domain/transit/usecase/transit_point_suggestions.dart';
import 'package:walk/presentation/transit/cubit/point_picker_cubit.dart';

class _MockStations extends Mock implements SearchStations {}

class _MockAddress extends Mock implements AddressSearch {}

class _MockSuggestions extends Mock implements TransitPointSuggestions {}

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

  setUp(() {
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

  PointPickerCubit make() => PointPickerCubit(stations, address, suggestions);

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

  test('composing does not call', () {
    fakeAsync((async) {
      final cubit = make();
      cubit.queryChanged('서울', composing: true);
      async.elapse(const Duration(seconds: 2));
      verifyNever(() => stations(any()));
      cubit.close();
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
}
