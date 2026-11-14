import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:walk/domain/weather/entity/forecast.dart';
import 'package:walk/domain/weather/entity/weather_condition.dart';
import 'package:walk/domain/weather/repository/weather_repository.dart';
import 'package:walk/domain/weather/weather_problem.dart';

/// Open-Meteo(키 없음)로 7일 예보를 가져온다.
@LazySingleton(as: WeatherRepository)
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository(
    this._client, {
    @ignoreParam Duration timeout = const Duration(seconds: 10),
  }) : _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  static const _current =
      'temperature_2m,apparent_temperature,weather_code,is_day,'
      'relative_humidity_2m,wind_speed_10m,precipitation';
  static const _hourly =
      'temperature_2m,precipitation_probability,precipitation,'
      'weather_code,is_day';
  static const _daily =
      'weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_probability_max,precipitation_sum,sunrise,sunset';

  @override
  Future<FetchedForecast> fetch(double lat, double lng) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lng',
      'timezone': 'auto',
      'forecast_days': '7',
      'wind_speed_unit': 'ms',
      'current': _current,
      'hourly': _hourly,
      'daily': _daily,
    });

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on IOException {
      // SocketException · HandshakeException · TlsException 등.
      throw const WeatherFailure(WeatherProblem.offline);
    } on TimeoutException {
      throw const WeatherFailure(WeatherProblem.offline);
    } on http.ClientException {
      throw const WeatherFailure(WeatherProblem.offline);
    }

    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      throw const WeatherFailure(WeatherProblem.server);
    }
    final payload = utf8.decode(response.bodyBytes, allowMalformed: true);
    return FetchedForecast(forecast: decode(payload), payload: payload);
  }

  @override
  Forecast decode(String payload) {
    try {
      final body = jsonDecode(payload);
      if (body is! Map) throw const FormatException('body');
      return _parse(body);
    } on WeatherFailure {
      rethrow;
    } catch (_) {
      // 필드 누락 · 형식 불일치(FormatException, TypeError 등).
      throw const WeatherFailure(WeatherProblem.server);
    }
  }

  Forecast _parse(Map body) {
    final offset = Duration(
      seconds: (body['utc_offset_seconds'] as num).toInt(),
    );
    // 지역 시각 문자열("2026-11-14T15:00")을 UTC 절대 시각으로.
    DateTime instant(Object? s) =>
        DateTime.parse('${s as String}Z').subtract(offset);

    final cur = body['current'] as Map;
    final current = CurrentWeather(
      time: instant(cur['time']),
      temperature: (cur['temperature_2m'] as num).toDouble(),
      apparentTemperature: (cur['apparent_temperature'] as num).toDouble(),
      condition: WeatherCondition.fromWmo((cur['weather_code'] as num).toInt()),
      isDay: (cur['is_day'] as num).toInt() == 1,
      humidity: (cur['relative_humidity_2m'] as num).toInt(),
      windSpeed: (cur['wind_speed_10m'] as num).toDouble(),
      precipitation: (cur['precipitation'] as num).toDouble(),
    );

    final h = body['hourly'] as Map;
    final hTime = h['time'] as List;
    final hourly = [
      for (var i = 0; i < hTime.length; i++)
        HourlyWeather(
          time: instant(hTime[i]),
          temperature: ((h['temperature_2m'] as List)[i] as num).toDouble(),
          precipitationProbability:
              ((h['precipitation_probability'] as List)[i] as num?)?.toInt(),
          precipitation: ((h['precipitation'] as List)[i] as num).toDouble(),
          condition: WeatherCondition.fromWmo(
            ((h['weather_code'] as List)[i] as num).toInt(),
          ),
          isDay: ((h['is_day'] as List)[i] as num).toInt() == 1,
        ),
    ];

    final d = body['daily'] as Map;
    final dTime = d['time'] as List;
    DateTime? optional(Object? s) => s == null ? null : instant(s);
    final daily = [
      for (var i = 0; i < dTime.length; i++)
        DailyWeather(
          // "2026-11-14" → 지역 자정.
          date: instant('${dTime[i]}T00:00'),
          condition: WeatherCondition.fromWmo(
            ((d['weather_code'] as List)[i] as num).toInt(),
          ),
          tempMax: ((d['temperature_2m_max'] as List)[i] as num).toDouble(),
          tempMin: ((d['temperature_2m_min'] as List)[i] as num).toDouble(),
          precipitationProbabilityMax:
              ((d['precipitation_probability_max'] as List)[i] as num?)
                  ?.toInt(),
          precipitationSum: ((d['precipitation_sum'] as List)[i] as num)
              .toDouble(),
          sunrise: optional((d['sunrise'] as List)[i]),
          sunset: optional((d['sunset'] as List)[i]),
        ),
    ];

    return Forecast(
      utcOffset: offset,
      current: current,
      hourly: hourly,
      daily: daily,
    );
  }
}
