import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/weather/entity/forecast.dart';
import 'package:walk/domain/weather/entity/weather_condition.dart';
import 'package:walk/domain/weather/repository/weather_repository.dart';
import 'package:walk/domain/weather/weather_cache.dart';
import 'package:walk/domain/weather/weather_locator.dart';
import 'package:walk/domain/weather/weather_problem.dart';
import 'package:walk/presentation/weather/cubit/weather_cubit.dart';
import 'package:walk/presentation/weather/cubit/weather_state.dart';

class _MockRepository extends Mock implements WeatherRepository {}

class _MockLocator extends Mock implements WeatherLocator {}

class _MockCache extends Mock implements WeatherCache {}

class _FakeClock extends Clock {
  _FakeClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

final _now = DateTime.utc(2026, 11, 14, 5);

Forecast _forecast(double temperature) => Forecast(
  utcOffset: const Duration(hours: 9),
  current: CurrentWeather(
    time: _now,
    temperature: temperature,
    apparentTemperature: temperature - 1,
    condition: WeatherCondition.cloudy,
    isDay: true,
    humidity: 50,
    windSpeed: 1,
    precipitation: 0,
  ),
  hourly: const [],
  daily: const [],
);

final _cachedForecast = _forecast(3);
final _freshForecast = _forecast(12);

/// 캐시 좌표(망원동)와 지금 위치(다른 곳).
const _cacheLat = 37.55, _cacheLng = 126.90;
const _hereLat = 35.15, _hereLng = 129.05;

CachedForecast _cache({required Duration age}) => CachedForecast(
  payload: 'cached',
  lat: _cacheLat,
  lng: _cacheLng,
  placeName: '망원동',
  fetchedAt: _now.subtract(age),
);

void main() {
  late _MockRepository repository;
  late _MockLocator locator;
  late _MockCache cache;
  late _FakeClock clock;

  setUpAll(() {
    registerFallbackValue(_cache(age: Duration.zero));
    registerFallbackValue(WeatherProblem.server);
  });

  setUp(() {
    repository = _MockRepository();
    locator = _MockLocator();
    cache = _MockCache();
    clock = _FakeClock(_now);
    when(() => cache.read()).thenAnswer((_) async => null);
    when(() => cache.write(any())).thenAnswer((_) async {});
    when(() => repository.decode('cached')).thenReturn(_cachedForecast);
    when(
      () => locator.locate(),
    ).thenAnswer((_) async => const WeatherFix.located(_hereLat, _hereLng));
    when(() => locator.placeName(any(), any())).thenAnswer((_) async => '해운대');
    when(() => locator.resolve(any())).thenAnswer((_) async {});
    when(() => repository.fetch(any(), any())).thenAnswer(
      (_) async => FetchedForecast(forecast: _freshForecast, payload: 'fresh'),
    );
  });

  WeatherCubit build() => WeatherCubit(repository, locator, cache, clock);

  const fresh = WeatherState.loaded;

  test('처음 상태는 loading', () {
    expect(build().state, const WeatherState.loading());
  });

  blocTest<WeatherCubit, WeatherState>(
    '캐시 없음 + 성공 → loading 뒤 loaded, 캐시에 쓴다',
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [
      // 처음 상태가 loading 이라 다시 내보내지 않는다.
      fresh(forecast: _freshForecast, placeName: '해운대', fetchedAt: _now),
    ],
    verify: (_) {
      verify(() => repository.fetch(_hereLat, _hereLng)).called(1);
      final written =
          verify(() => cache.write(captureAny())).captured.last
              as CachedForecast;
      expect(
        written,
        CachedForecast(
          payload: 'fresh',
          lat: _hereLat,
          lng: _hereLng,
          placeName: '해운대',
          fetchedAt: _now,
        ),
      );
    },
  );

  blocTest<WeatherCubit, WeatherState>(
    '유효 캐시 → 캐시 예보를 refreshing 으로 먼저, 그다음 새 예보',
    setUp: () => when(
      () => cache.read(),
    ).thenAnswer((_) async => _cache(age: const Duration(hours: 3))),
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [
      fresh(
        forecast: _cachedForecast,
        placeName: '망원동',
        fetchedAt: _now.subtract(const Duration(hours: 3)),
        refreshing: true,
      ),
      fresh(forecast: _freshForecast, placeName: '해운대', fetchedAt: _now),
    ],
  );

  blocTest<WeatherCubit, WeatherState>(
    '25시간 된 캐시는 버리고 loading 부터',
    setUp: () => when(
      () => cache.read(),
    ).thenAnswer((_) async => _cache(age: const Duration(hours: 25))),
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [
      fresh(forecast: _freshForecast, placeName: '해운대', fetchedAt: _now),
    ],
    verify: (_) => verifyNever(() => repository.decode(any())),
  );

  blocTest<WeatherCubit, WeatherState>(
    '25시간 된 캐시는 위치 실패 때도 쓰지 않는다 → empty',
    setUp: () {
      when(
        () => cache.read(),
      ).thenAnswer((_) async => _cache(age: const Duration(hours: 25)));
      when(() => locator.locate()).thenAnswer(
        (_) async => const WeatherFix.failed(WeatherProblem.locationDenied),
      );
    },
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [const WeatherState.empty(WeatherProblem.locationDenied)],
  );

  blocTest<WeatherCubit, WeatherState>(
    '깨진 캐시는 없는 것으로 본다',
    setUp: () {
      when(
        () => cache.read(),
      ).thenAnswer((_) async => _cache(age: const Duration(hours: 1)));
      when(
        () => repository.decode('cached'),
      ).thenThrow(const WeatherFailure(WeatherProblem.server));
    },
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [
      fresh(forecast: _freshForecast, placeName: '해운대', fetchedAt: _now),
    ],
  );

  blocTest<WeatherCubit, WeatherState>(
    'shown: 5분 전 성공이면 요청하지 않는다',
    setUp: () => when(
      () => cache.read(),
    ).thenAnswer((_) async => _cache(age: const Duration(minutes: 5))),
    build: build,
    act: (cubit) async {
      await cubit.shown();
      await cubit.resumed();
    },
    expect: () => [
      fresh(
        forecast: _cachedForecast,
        placeName: '망원동',
        fetchedAt: _now.subtract(const Duration(minutes: 5)),
      ),
    ],
    verify: (_) {
      verifyNever(() => locator.locate());
      verifyNever(() => repository.fetch(any(), any()));
    },
  );

  blocTest<WeatherCubit, WeatherState>(
    'shown: 성공 뒤 10분이 지나면 다시 요청한다',
    build: build,
    act: (cubit) async {
      await cubit.shown();
      clock.value = _now.add(const Duration(minutes: 9));
      await cubit.resumed();
      clock.value = _now.add(const Duration(minutes: 11));
      await cubit.shown();
    },
    verify: (_) => verify(() => repository.fetch(any(), any())).called(2),
  );

  blocTest<WeatherCubit, WeatherState>(
    'refresh 는 5분 전이어도 요청한다',
    setUp: () => when(
      () => cache.read(),
    ).thenAnswer((_) async => _cache(age: const Duration(minutes: 5))),
    build: build,
    act: (cubit) => cubit.refresh(),
    expect: () => [
      fresh(
        forecast: _cachedForecast,
        placeName: '망원동',
        fetchedAt: _now.subtract(const Duration(minutes: 5)),
        refreshing: true,
      ),
      fresh(forecast: _freshForecast, placeName: '해운대', fetchedAt: _now),
    ],
    verify: (_) => verify(() => repository.fetch(any(), any())).called(1),
  );

  blocTest<WeatherCubit, WeatherState>(
    '요청 실패 뒤 shown 은 10분 안이라도 다시 요청한다',
    setUp: () => when(
      () => cache.read(),
    ).thenAnswer((_) async => _cache(age: const Duration(minutes: 5))),
    build: build,
    act: (cubit) async {
      when(
        () => repository.fetch(any(), any()),
      ).thenThrow(const WeatherFailure(WeatherProblem.offline));
      await cubit.refresh();
      await cubit.shown();
    },
    verify: (_) => verify(() => repository.fetch(any(), any())).called(2),
  );

  blocTest<WeatherCubit, WeatherState>(
    '위치 거부 + 캐시 → 캐시 좌표로 요청, problem: locationDenied, placeName 은 캐시 것',
    setUp: () {
      when(
        () => cache.read(),
      ).thenAnswer((_) async => _cache(age: const Duration(hours: 3)));
      when(() => locator.locate()).thenAnswer(
        (_) async => const WeatherFix.failed(WeatherProblem.locationDenied),
      );
    },
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [
      fresh(
        forecast: _cachedForecast,
        placeName: '망원동',
        fetchedAt: _now.subtract(const Duration(hours: 3)),
        refreshing: true,
      ),
      fresh(
        forecast: _freshForecast,
        placeName: '망원동',
        fetchedAt: _now,
        problem: WeatherProblem.locationDenied,
      ),
    ],
    verify: (_) {
      verify(() => repository.fetch(_cacheLat, _cacheLng)).called(1);
      verifyNever(() => locator.placeName(any(), any()));
      final written =
          verify(() => cache.write(captureAny())).captured.single
              as CachedForecast;
      expect(written.placeName, '망원동');
      expect(written.lat, _cacheLat);
    },
  );

  blocTest<WeatherCubit, WeatherState>(
    '위치 거부 + 캐시 없음 → empty(locationDenied)',
    setUp: () => when(() => locator.locate()).thenAnswer(
      (_) async => const WeatherFix.failed(WeatherProblem.locationDenied),
    ),
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [const WeatherState.empty(WeatherProblem.locationDenied)],
    verify: (_) => verifyNever(() => repository.fetch(any(), any())),
  );

  blocTest<WeatherCubit, WeatherState>(
    '오프라인 + 캐시 → loaded(stale: true, problem: offline)',
    setUp: () {
      when(
        () => cache.read(),
      ).thenAnswer((_) async => _cache(age: const Duration(hours: 3)));
      when(
        () => repository.fetch(any(), any()),
      ).thenThrow(const WeatherFailure(WeatherProblem.offline));
    },
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [
      fresh(
        forecast: _cachedForecast,
        placeName: '망원동',
        fetchedAt: _now.subtract(const Duration(hours: 3)),
        refreshing: true,
      ),
      fresh(
        forecast: _cachedForecast,
        placeName: '망원동',
        fetchedAt: _now.subtract(const Duration(hours: 3)),
        stale: true,
        problem: WeatherProblem.offline,
      ),
    ],
    verify: (_) => verifyNever(() => cache.write(any())),
  );

  blocTest<WeatherCubit, WeatherState>(
    '오프라인 + 캐시 없음 → empty(offline)',
    setUp: () => when(
      () => repository.fetch(any(), any()),
    ).thenThrow(const WeatherFailure(WeatherProblem.offline)),
    build: build,
    act: (cubit) => cubit.shown(),
    expect: () => [const WeatherState.empty(WeatherProblem.offline)],
  );

  blocTest<WeatherCubit, WeatherState>(
    'empty 뒤 다시 시도하면 loading 을 거쳐 loaded',
    build: build,
    act: (cubit) async {
      when(
        () => repository.fetch(any(), any()),
      ).thenThrow(const WeatherFailure(WeatherProblem.server));
      await cubit.shown();
      when(() => repository.fetch(any(), any())).thenAnswer(
        (_) async =>
            FetchedForecast(forecast: _freshForecast, payload: 'fresh'),
      );
      await cubit.refresh();
    },
    expect: () => [
      const WeatherState.empty(WeatherProblem.server),
      const WeatherState.loading(),
      fresh(forecast: _freshForecast, placeName: '해운대', fetchedAt: _now),
    ],
  );

  group('장소 이름', () {
    late Completer<String?> name;

    setUp(() {
      // 조회할 때 만든다 — 에러가 blocTest 의 zone 을 넘어가지 못하므로 같은 zone 에서.
      when(
        () => locator.placeName(any(), any()),
      ).thenAnswer((_) => (name = Completer<String?>()).future);
    });

    blocTest<WeatherCubit, WeatherState>(
      '이름이 예보보다 늦게 오면 예보 먼저, 이름은 나중에',
      build: build,
      act: (cubit) async {
        await cubit.shown();
        name.complete('해운대');
        await pumpEventQueue();
      },
      expect: () => [
        fresh(forecast: _freshForecast, fetchedAt: _now),
        fresh(forecast: _freshForecast, placeName: '해운대', fetchedAt: _now),
      ],
      verify: (_) {
        verify(() => locator.placeName(_hereLat, _hereLng)).called(1);
        final writes = verify(
          () => cache.write(captureAny()),
        ).captured.cast<CachedForecast>();
        expect(writes.map((w) => w.placeName), [null, '해운대']);
      },
    );

    blocTest<WeatherCubit, WeatherState>(
      '이름 실패 → placeName null',
      build: build,
      act: (cubit) async {
        await cubit.shown();
        name.completeError(Exception('geocoder'));
        await pumpEventQueue();
      },
      expect: () => [fresh(forecast: _freshForecast, fetchedAt: _now)],
      verify: (_) => verify(() => cache.write(any())).called(1),
    );

    blocTest<WeatherCubit, WeatherState>(
      '늦게 온 이름은 그사이 다른 좌표로 바뀌었으면 버린다',
      build: build,
      act: (cubit) async {
        await cubit.shown();
        final second = Completer<String?>();
        when(
          () => locator.locate(),
        ).thenAnswer((_) async => const WeatherFix.located(1, 2));
        when(() => locator.placeName(1, 2)).thenAnswer((_) => second.future);
        await cubit.refresh();
        name.complete('해운대');
        await pumpEventQueue();
      },
      expect: () => [
        fresh(forecast: _freshForecast, fetchedAt: _now),
        fresh(forecast: _freshForecast, fetchedAt: _now, refreshing: true),
        fresh(forecast: _freshForecast, fetchedAt: _now),
      ],
    );
  });

  blocTest<WeatherCubit, WeatherState>(
    'refresh 와 shown 이 겹쳐도 fetch 는 한 번',
    build: build,
    act: (cubit) async {
      final a = cubit.refresh();
      final b = cubit.shown();
      final c = cubit.resumed();
      await Future.wait([a, b, c]);
    },
    verify: (_) {
      verify(() => locator.locate()).called(1);
      verify(() => repository.fetch(any(), any())).called(1);
    },
  );

  blocTest<WeatherCubit, WeatherState>(
    'resolve(locationDenied) → locator.resolve 뒤 refresh',
    setUp: () => when(
      () => cache.read(),
    ).thenAnswer((_) async => _cache(age: const Duration(minutes: 5))),
    build: build,
    act: (cubit) => cubit.resolve(WeatherProblem.locationDenied),
    verify: (_) {
      verifyInOrder([
        () => locator.resolve(WeatherProblem.locationDenied),
        () => repository.fetch(_hereLat, _hereLng),
      ]);
    },
  );

  blocTest<WeatherCubit, WeatherState>(
    'resolve 가 던져도 refresh 한다',
    setUp: () => when(
      () => locator.resolve(any()),
    ).thenThrow(Exception('no settings activity')),
    build: build,
    act: (cubit) => cubit.resolve(WeatherProblem.locationServiceOff),
    expect: () => [
      fresh(forecast: _freshForecast, placeName: '해운대', fetchedAt: _now),
    ],
  );

  test('close 뒤에 끝난 요청은 내보내지 않는다', () async {
    final fetch = Completer<FetchedForecast>();
    when(() => repository.fetch(any(), any())).thenAnswer((_) => fetch.future);
    final cubit = build();
    final run = cubit.shown();
    await pumpEventQueue();
    await cubit.close();
    fetch.complete(FetchedForecast(forecast: _freshForecast, payload: 'fresh'));
    await run;
    expect(cubit.state, const WeatherState.loading());
  });
}
