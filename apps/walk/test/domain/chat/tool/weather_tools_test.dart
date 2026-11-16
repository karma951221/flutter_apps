import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/tool/weather_tools.dart';
import 'package:walk/domain/weather/entity/forecast.dart';
import 'package:walk/domain/weather/entity/weather_condition.dart';
import 'package:walk/domain/weather/repository/weather_repository.dart';
import 'package:walk/domain/weather/weather_cache.dart';
import 'package:walk/domain/weather/weather_locator.dart';
import 'package:walk/domain/weather/weather_problem.dart';

class _Repo extends Mock implements WeatherRepository {}

class _Locator extends Mock implements WeatherLocator {}

class _Cache extends Mock implements WeatherCache {}

class _FixedClock extends Clock {
  const _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

// 2026-11-16 12:00 KST = 03:00Z. 예보 지역 오프셋 +9h.
final _now = DateTime.utc(2026, 11, 16, 3);

Forecast _forecast() => Forecast(
  utcOffset: const Duration(hours: 9),
  current: CurrentWeather(
    time: _now,
    temperature: 12.3,
    apparentTemperature: 10.1,
    condition: WeatherCondition.cloudy,
    isDay: true,
    humidity: 60,
    windSpeed: 2.5,
    precipitation: 0,
  ),
  hourly: [
    for (var h = -2; h < 30; h++)
      HourlyWeather(
        time: _now.add(Duration(hours: h)),
        temperature: 10.0 + h,
        precipitationProbability: 30,
        precipitation: 0.2,
        condition: WeatherCondition.rain,
        isDay: true,
      ),
  ],
  daily: [
    for (var d = 0; d < 8; d++)
      DailyWeather(
        date: DateTime.utc(2026, 11, 15 + d, 15), // 지역 자정(11-16 + d)
        condition: WeatherCondition.clear,
        tempMax: 15,
        tempMin: 5,
        precipitationProbabilityMax: 10,
        precipitationSum: 0,
      ),
  ],
);

CachedForecast _cached(Duration age) => CachedForecast(
  payload: 'cached',
  lat: 37.5,
  lng: 127.0,
  placeName: '역삼동',
  fetchedAt: _now.subtract(age),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_cached(Duration.zero));
  });

  late _Repo repo;
  late _Locator locator;
  late _Cache cache;
  late WeatherTools tools;

  setUp(() {
    repo = _Repo();
    locator = _Locator();
    cache = _Cache();
    tools = WeatherTools(repo, locator, cache, _FixedClock(_now));
    when(() => repo.decode(any())).thenReturn(_forecast());
    when(() => cache.read()).thenAnswer((_) async => null);
    when(() => cache.write(any())).thenAnswer((_) async {});
    when(
      () => locator.locate(),
    ).thenAnswer((_) async => const WeatherFix.located(37.4, 127.1));
    when(() => locator.placeName(any(), any())).thenAnswer((_) async => '서초동');
    when(() => repo.fetch(any(), any())).thenAnswer(
      (_) async => FetchedForecast(forecast: _forecast(), payload: 'fresh'),
    );
  });

  Future<Map<String, Object?>> ok() async {
    final r = await tools.run();
    expect(r.isError, isFalse, reason: r.json);
    expect(r.summary?.kind, ChatToolKind.weather);
    return jsonDecode(r.json) as Map<String, Object?>;
  }

  test('정의 이름은 weather_forecast', () {
    expect(tools.definition.name, 'weather_forecast');
  });

  test('10분 안 캐시는 새로 받지 않는다', () async {
    when(
      () => cache.read(),
    ).thenAnswer((_) async => _cached(const Duration(minutes: 5)));
    final json = await ok();
    verifyNever(() => repo.fetch(any(), any()));
    verifyNever(() => locator.locate());
    expect(json['place'], '역삼동');
    expect(json.containsKey('stale'), isFalse);
  });

  test('캐시가 없으면 지금 위치로 받아 캐시에 쓰고, 좌표는 보내지 않는다', () async {
    final r = await tools.run();
    verify(() => repo.fetch(37.4, 127.1)).called(1);
    final saved =
        verify(() => cache.write(captureAny())).captured.single
            as CachedForecast;
    expect(saved.payload, 'fresh');
    expect(saved.placeName, '서초동');
    expect(r.json, isNot(contains('37.4')));
    expect(r.json, isNot(contains('lat')));
    final json = jsonDecode(r.json) as Map;
    expect(json['place'], '서초동');
    expect(json['fetched_at'], '2026-11-16T12:00');
  });

  test('지금 · 지금 이후 24칸 · 7일을 지역 벽시계로 준다', () async {
    final json = await ok();
    expect(json['current'], {
      'temp': 12.3,
      'feels_like': 10.1,
      'condition': 'cloudy',
      'humidity': 60,
      'wind': 2.5,
      'precipitation': 0.0,
    });
    final hourly = json['hourly']! as List;
    expect(hourly, hasLength(24));
    expect(hourly.first, {
      'time': '2026-11-16T12:00',
      'temp': 10.0,
      'pop': 30,
      'precipitation': 0.2,
      'condition': 'rain',
    });
    final daily = json['daily']! as List;
    expect(daily, hasLength(7));
    expect(daily.first, {
      'date': '2026-11-16',
      'condition': 'clear',
      'max': 15.0,
      'min': 5.0,
      'pop': 10,
      'precipitation': 0.0,
    });
  });

  test('이름 조회가 실패해도 예보는 준다', () async {
    when(() => locator.placeName(any(), any())).thenThrow(Exception('x'));
    final json = await ok();
    expect(json['place'], isNull);
  });

  test('위치를 못 얻으면 캐시 좌표로 새로 받는다', () async {
    when(
      () => cache.read(),
    ).thenAnswer((_) async => _cached(const Duration(hours: 2)));
    when(() => locator.locate()).thenAnswer(
      (_) async => const WeatherFix.failed(WeatherProblem.locationDenied),
    );
    final json = await ok();
    verify(() => repo.fetch(37.5, 127.0)).called(1);
    expect(json['place'], '역삼동');
    expect(json.containsKey('stale'), isFalse);
  });

  test('받기가 실패하면 24시간 안 캐시로 답하고 stale', () async {
    when(
      () => cache.read(),
    ).thenAnswer((_) async => _cached(const Duration(hours: 2)));
    when(() => repo.fetch(any(), any())).thenThrow(Exception('offline'));
    final json = await ok();
    expect(json['stale'], isTrue);
    expect(json['fetched_at'], '2026-11-16T10:00');
  });

  test('위치 실패 + 캐시가 24시간 넘으면 weather_unavailable', () async {
    when(
      () => cache.read(),
    ).thenAnswer((_) async => _cached(const Duration(hours: 25)));
    when(() => locator.locate()).thenAnswer(
      (_) async => const WeatherFix.failed(WeatherProblem.locationDenied),
    );
    final r = await tools.run();
    expect(r.isError, isTrue);
    expect(jsonDecode(r.json), {'error': 'weather_unavailable'});
    verifyNever(() => repo.fetch(any(), any()));
  });

  test('받기 실패 + 캐시 없음이면 weather_unavailable', () async {
    when(() => repo.fetch(any(), any())).thenThrow(Exception('offline'));
    final r = await tools.run();
    expect(jsonDecode(r.json), {'error': 'weather_unavailable'});
  });
}
