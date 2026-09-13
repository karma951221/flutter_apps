import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommuteUseCase extends Mock implements CommuteUseCase {}

const _station = Station(
  id: '0222',
  name: '강남',
  lines: ['2', '신분당'],
  location: GeoPoint(lat: 37.4979, lng: 127.0276),
);

void main() {
  late _MockCommuteUseCase useCase;

  setUp(() => useCase = _MockCommuteUseCase());

  blocTest<StationSearchCubit, StationSearchState>(
    '300ms 뒤 역을 검색한다',
    build: () {
      when(
        () => useCase.searchStations('강남'),
      ).thenAnswer((_) async => const Ok([_station]));
      return StationSearchCubit(useCase);
    },
    act: (cubit) => cubit.search(' 강남 '),
    wait: const Duration(milliseconds: 350),
    expect: () => const [
      StationSearchState.searching('강남'),
      StationSearchState.results('강남', [_station]),
    ],
    verify: (_) => verify(() => useCase.searchStations('강남')).called(1),
  );

  blocTest<StationSearchCubit, StationSearchState>(
    '새 질의가 들어오면 이전 디바운스를 취소한다',
    build: () {
      when(
        () => useCase.searchStations('강남'),
      ).thenAnswer((_) async => const Ok([_station]));
      return StationSearchCubit(useCase);
    },
    act: (cubit) {
      cubit
        ..search('장승배기')
        ..search('강남');
    },
    wait: const Duration(milliseconds: 350),
    expect: () => const [
      StationSearchState.searching('장승배기'),
      StationSearchState.searching('강남'),
      StationSearchState.results('강남', [_station]),
    ],
    verify: (_) {
      verifyNever(() => useCase.searchStations('장승배기'));
      verify(() => useCase.searchStations('강남')).called(1);
    },
  );

  blocTest<StationSearchCubit, StationSearchState>(
    '빈 질의는 검색하지 않고 idle로 돌아간다',
    build: () => StationSearchCubit(useCase),
    act: (cubit) {
      cubit
        ..search('강남')
        ..search('   ');
    },
    wait: const Duration(milliseconds: 350),
    expect: () => const [
      StationSearchState.searching('강남'),
      StationSearchState.idle(),
    ],
    verify: (_) => verifyNever(() => useCase.searchStations(any())),
  );
}
