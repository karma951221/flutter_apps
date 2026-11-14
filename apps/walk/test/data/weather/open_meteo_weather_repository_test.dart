import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/weather/open_meteo_weather_repository.dart';
import 'package:walk/domain/weather/entity/weather_condition.dart';
import 'package:walk/domain/weather/weather_problem.dart';

String _fixture() =>
    File('test/fixtures/weather/open_meteo_seoul.json').readAsStringSync();

http.Response _json(String body, [int status = 200]) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {'content-type': 'application/json'},
);

OpenMeteoWeatherRepository _build(
  Future<http.Response> Function(http.Request) handler,
) => OpenMeteoWeatherRepository(MockClient(handler));

Matcher _failure(WeatherProblem p) =>
    throwsA(isA<WeatherFailure>().having((e) => e.problem, 'problem', p));

void main() {
  test('요청 URL 에 스펙의 파라미터가 모두 있다', () async {
    late Uri uri;
    final repo = _build((r) async {
      uri = r.url;
      return _json(_fixture());
    });
    await repo.fetch(37.5665, 126.978);

    expect(uri.host, 'api.open-meteo.com');
    expect(uri.path, '/v1/forecast');
    final q = uri.queryParameters;
    expect(q['latitude'], '37.5665');
    expect(q['longitude'], '126.978');
    expect(q['timezone'], 'auto');
    expect(q['forecast_days'], '7');
    expect(q['wind_speed_unit'], 'ms');
    expect(
      q['current'],
      'temperature_2m,apparent_temperature,weather_code,is_day,'
      'relative_humidity_2m,wind_speed_10m,precipitation',
    );
    expect(
      q['hourly'],
      'temperature_2m,precipitation_probability,precipitation,'
      'weather_code,is_day',
    );
    expect(
      q['daily'],
      'weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_probability_max,precipitation_sum,sunrise,sunset',
    );
  });

  test('픽스처를 엔티티로 바꾼다', () async {
    final body = _fixture();
    final raw = jsonDecode(body) as Map<String, dynamic>;
    final repo = _build((_) async => _json(body));
    final fetched = await repo.fetch(37.5665, 126.978);
    final f = fetched.forecast;

    expect(f.utcOffset, const Duration(hours: 9));
    expect(f.hourly, hasLength(168));
    expect(f.daily, hasLength(7));
    expect(fetched.payload, body);

    final hourlyRaw = raw['hourly'] as Map<String, dynamic>;
    final firstLocal = (hourlyRaw['time'] as List).first as String;
    expect(
      f.hourly.first.time,
      DateTime.parse('${firstLocal}Z').subtract(const Duration(hours: 9)),
    );
    expect(f.hourly.first.time.isUtc, isTrue);
    expect(
      f.hourly.first.temperature,
      (hourlyRaw['temperature_2m'] as List).first,
    );
    expect(
      f.hourly.first.condition,
      WeatherCondition.fromWmo(
        (hourlyRaw['weather_code'] as List).first as int,
      ),
    );

    final cur = raw['current'] as Map<String, dynamic>;
    expect(
      f.current.time,
      DateTime.parse('${cur['time']}Z').subtract(const Duration(hours: 9)),
    );
    expect(f.current.temperature, cur['temperature_2m']);
    expect(f.current.apparentTemperature, cur['apparent_temperature']);
    expect(f.current.condition, WeatherCondition.fromWmo(cur['weather_code']));
    expect(f.current.isDay, cur['is_day'] == 1);
    expect(f.current.humidity, cur['relative_humidity_2m']);
    expect(f.current.windSpeed, cur['wind_speed_10m']);
    expect(f.current.precipitation, cur['precipitation']);

    final dailyRaw = raw['daily'] as Map<String, dynamic>;
    final d0 = f.daily.first;
    expect(
      d0.date,
      DateTime.parse(
        '${(dailyRaw['time'] as List).first}T00:00:00Z',
      ).subtract(const Duration(hours: 9)),
    );
    expect(d0.tempMax, (dailyRaw['temperature_2m_max'] as List).first);
    expect(d0.tempMin, (dailyRaw['temperature_2m_min'] as List).first);
    expect(d0.sunrise, isNotNull);
    expect(d0.sunrise!.isUtc, isTrue);
    expect(
      d0.sunrise,
      DateTime.parse(
        '${(dailyRaw['sunrise'] as List).first}Z',
      ).subtract(const Duration(hours: 9)),
    );
  });

  test('decode(payload) 는 fetch 와 같은 Forecast', () async {
    final repo = _build((_) async => _json(_fixture()));
    final fetched = await repo.fetch(37.5665, 126.978);
    expect(repo.decode(fetched.payload), fetched.forecast);
  });

  test('precipitation_probability 가 null 인 칸은 null', () async {
    final raw = jsonDecode(_fixture()) as Map<String, dynamic>;
    final probs =
        (raw['hourly'] as Map<String, dynamic>)['precipitation_probability']
            as List;
    probs[3] = null;
    final repo = _build((_) async => _json(jsonEncode(raw)));
    final f = (await repo.fetch(37.5, 127)).forecast;
    expect(f.hourly[3].precipitationProbability, isNull);
    expect(f.hourly[2].precipitationProbability, isNotNull);
  });

  test('필드가 빠지면 WeatherFailure(server)', () async {
    final raw = jsonDecode(_fixture()) as Map<String, dynamic>;
    (raw['hourly'] as Map<String, dynamic>).remove('temperature_2m');
    final repo = _build((_) async => _json(jsonEncode(raw)));
    await expectLater(repo.fetch(37.5, 127), _failure(WeatherProblem.server));
    expect(() => repo.decode('not json'), _failure(WeatherProblem.server));
  });

  test('HTTP 500 → server', () async {
    final repo = _build((_) async => _json('{}', 500));
    await expectLater(repo.fetch(37.5, 127), _failure(WeatherProblem.server));
  });

  test(
    'SocketException · TimeoutException · ClientException → offline',
    () async {
      for (final error in <Object>[
        const SocketException('x'),
        TimeoutException('x'),
        http.ClientException('x'),
      ]) {
        final repo = _build((_) async => throw error);
        await expectLater(
          repo.fetch(37.5, 127),
          _failure(WeatherProblem.offline),
        );
      }
    },
  );
}
