import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransitRouteRepository extends Mock
    implements TransitRouteRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

class _MockStationRepository extends Mock implements StationRepository {}

class _MockCommuteSettingsRepository extends Mock
    implements CommuteSettingsRepository {}

const _home = Station(
  id: '0739',
  name: '장승배기',
  lines: ['7'],
  location: GeoPoint(lat: 37.5048, lng: 126.9391),
);
const _work = Station(
  id: '0222',
  name: '강남',
  lines: ['2', '신분당'],
  location: GeoPoint(lat: 37.4979, lng: 127.0276),
);
const _current = GeoPoint(lat: 37.51, lng: 127.01);
const _routes = <TransitRoute>[
  TransitRoute(
    mode: TransitMode.subway,
    duration: Duration(minutes: 31),
    transferCount: 1,
    legs: [
      TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 4),
      TransitLeg(kind: TransitLegKind.subway, label: '7호선', minutes: 23),
      TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 4),
    ],
  ),
];

void main() {
  late _MockTransitRouteRepository transitRepository;
  late _MockLocationRepository locationRepository;
  late _MockStationRepository stationRepository;
  late _MockCommuteSettingsRepository settingsRepository;
  late CommuteUseCase useCase;

  setUp(() {
    transitRepository = _MockTransitRouteRepository();
    locationRepository = _MockLocationRepository();
    stationRepository = _MockStationRepository();
    settingsRepository = _MockCommuteSettingsRepository();
    useCase = DefaultCommuteUseCase(
      transitRepository,
      locationRepository,
      stationRepository,
      settingsRepository,
    );
  });

  void stubCompleteSettings() {
    when(() => settingsRepository.load()).thenAnswer(
      (_) async => const Ok(CommuteSettings(home: _home, work: _work)),
    );
  }

  void stubLocationFailure() {
    when(
      () => locationRepository.currentLocation(
        timeout: const Duration(seconds: 5),
      ),
    ).thenAnswer(
      (_) async => const Err(
        Failure.forbidden(failureCode: FailureCode.locationPermissionDenied),
      ),
    );
  }

  test('설정이 미완성이면 commuteNotConfigured 실패를 반환한다', () async {
    when(
      () => settingsRepository.load(),
    ).thenAnswer((_) async => const Ok(CommuteSettings(home: _home)));

    final result = await useCase.searchCommute(CommuteDirection.toWork);

    expect(
      result,
      const Err<CommuteResult>(
        Failure.validation(failureCode: FailureCode.commuteNotConfigured),
      ),
    );
    verifyNever(
      () => locationRepository.currentLocation(
        timeout: const Duration(seconds: 5),
      ),
    );
  });

  test('GPS 성공이면 현 위치를 출발지로 사용한다', () async {
    stubCompleteSettings();
    when(
      () => locationRepository.currentLocation(
        timeout: const Duration(seconds: 5),
      ),
    ).thenAnswer((_) async => const Ok(_current));
    when(
      () => transitRepository.search(
        origin: _current,
        destination: _work.location,
      ),
    ).thenAnswer((_) async => const Ok(_routes));

    final result = await useCase.searchCommute(CommuteDirection.toWork);

    final value = switch (result) {
      Ok<CommuteResult>(:final value) => value,
      Err<CommuteResult>(:final failure) => fail('예상하지 못한 실패: $failure'),
    };
    expect(value.direction, CommuteDirection.toWork);
    expect(value.origin, const Origin.currentLocation(_current));
    expect(value.destination, _work);
    expect(value.routes, _routes);
  });

  test('GPS 실패 시 출근은 집 역을 출발지로 사용한다', () async {
    stubCompleteSettings();
    stubLocationFailure();
    when(
      () => transitRepository.search(
        origin: _home.location,
        destination: _work.location,
      ),
    ).thenAnswer((_) async => const Ok(_routes));

    final result = await useCase.searchCommute(CommuteDirection.toWork);

    final value = (result as Ok<CommuteResult>).value;
    expect(value.origin, const Origin.fallbackStation(_home));
    expect(value.destination, _work);
  });

  test('GPS 실패 시 퇴근은 회사 역을 출발지로 사용한다', () async {
    stubCompleteSettings();
    stubLocationFailure();
    when(
      () => transitRepository.search(
        origin: _work.location,
        destination: _home.location,
      ),
    ).thenAnswer((_) async => const Ok(_routes));

    final result = await useCase.searchCommute(CommuteDirection.toHome);

    final value = (result as Ok<CommuteResult>).value;
    expect(value.origin, const Origin.fallbackStation(_work));
    expect(value.destination, _home);
  });

  test('경로 검색 실패를 그대로 전파한다', () async {
    stubCompleteSettings();
    when(
      () => locationRepository.currentLocation(
        timeout: const Duration(seconds: 5),
      ),
    ).thenAnswer((_) async => const Ok(_current));
    const failure = Failure.server(failureCode: FailureCode.routeSearchFailed);
    when(
      () => transitRepository.search(
        origin: _current,
        destination: _work.location,
      ),
    ).thenAnswer((_) async => const Err(failure));

    final result = await useCase.searchCommute(CommuteDirection.toWork);

    expect(result, isA<Err<CommuteResult>>());
    expect((result as Err<CommuteResult>).failure, failure);
  });
}
