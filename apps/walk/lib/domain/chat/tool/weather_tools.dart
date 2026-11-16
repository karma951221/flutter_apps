import 'dart:convert';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../weather/entity/forecast.dart';
import '../../weather/repository/weather_repository.dart';
import '../../weather/weather_cache.dart';
import '../../weather/weather_locator.dart';
import '../chat_model.dart';
import 'tool_input.dart';
import 'tool_result.dart';
import 'tool_summary.dart';

/// 물어보기 모델이 날씨 탭과 같은 위치의 예보를 읽는 도구. 좌표는 보내지 않는다.
///
/// 날씨 탭 규칙과 같다: 10분 안 캐시는 그대로, 아니면 새로 받고, 받지 못하면 24시간 안 캐시.
@lazySingleton
class WeatherTools {
  WeatherTools(this._repository, this._locator, this._cache, this._clock);

  final WeatherRepository _repository;
  final WeatherLocator _locator;
  final WeatherCache _cache;
  final Clock _clock;

  static const name = 'weather_forecast';

  /// `WeatherCubit.freshFor` 와 같은 값.
  static const _freshFor = Duration(minutes: 10);

  /// `WeatherCubit.cacheMaxAge` 와 같은 값.
  static const _cacheMaxAge = Duration(hours: 24);

  static const _hours = 24;
  static const _days = 7;

  ToolSpec get definition => const ToolSpec(
    name: name,
    description:
        '날씨 탭이 쓰는 위치의 예보(지금 · 앞으로 24시간 · 7일)를 본다. 지난 날씨 기록은 없다. '
        'stale 이 true 면 새로 받지 못해 fetched_at 에 받아 둔 예보다.',
    parameters: {'type': 'object', 'properties': {}, 'required': []},
  );

  Future<ToolResult> run() async {
    try {
      return await _run();
    } catch (_) {
      return toolError('tool_failed', ChatToolKind.weather);
    }
  }

  Future<ToolResult> _run() async {
    final now = _clock.now();
    CachedForecast? cached;
    try {
      cached = await _cache.read();
    } catch (_) {
      cached = null;
    }
    final age = cached == null ? null : now.difference(cached.fetchedAt);
    final usable = age != null && !age.isNegative && age <= _cacheMaxAge
        ? cached
        : null;
    if (usable != null && age! < _freshFor) {
      return _result(usable, _repository.decode(usable.payload), stale: false);
    }

    final fix = await _locator.locate();
    final double lat;
    final double lng;
    final bool located;
    switch (fix) {
      case WeatherLocated(lat: final fixLat, lng: final fixLng):
        lat = fixLat;
        lng = fixLng;
        located = true;
      case WeatherNoFix():
        if (usable == null) return _unavailable();
        lat = usable.lat;
        lng = usable.lng;
        located = false;
    }

    final FetchedForecast fetched;
    try {
      fetched = await _repository.fetch(lat, lng);
    } catch (_) {
      if (usable == null) return _unavailable();
      return _result(usable, _repository.decode(usable.payload), stale: true);
    }

    String? placeName;
    if (located) {
      try {
        placeName = await _locator.placeName(lat, lng);
      } catch (_) {
        placeName = null;
      }
    } else {
      placeName = usable?.placeName;
    }
    final saved = CachedForecast(
      payload: fetched.payload,
      lat: lat,
      lng: lng,
      placeName: placeName,
      fetchedAt: _clock.now(),
    );
    try {
      await _cache.write(saved);
    } catch (_) {
      // 캐시 쓰기 실패는 이번 답에 지장이 없다.
    }
    return _result(saved, fetched.forecast, stale: false);
  }

  static ToolResult _unavailable() =>
      toolError('weather_unavailable', ChatToolKind.weather);

  ToolResult _result(
    CachedForecast source,
    Forecast forecast, {
    required bool stale,
  }) {
    String wall(DateTime t) {
      final w = forecast.wallClock(t);
      return '${toolDay(w)}T${toolTime(w)}';
    }

    final now = _clock.now();
    final hourStart = now.toUtc().subtract(
      Duration(
        minutes: now.toUtc().minute,
        seconds: now.toUtc().second,
        milliseconds: now.toUtc().millisecond,
        microseconds: now.toUtc().microsecond,
      ),
    );
    final hourly = forecast.hourly
        .where((h) => !h.time.isBefore(hourStart))
        .take(_hours);
    final c = forecast.current;
    return ToolResult(
      json: jsonEncode({
        'place': source.placeName,
        'fetched_at': wall(source.fetchedAt),
        if (stale) 'stale': true,
        'current': {
          'temp': c.temperature,
          'feels_like': c.apparentTemperature,
          'condition': c.condition.name,
          'humidity': c.humidity,
          'wind': c.windSpeed,
          'precipitation': c.precipitation,
        },
        'hourly': [
          for (final h in hourly)
            {
              'time': wall(h.time),
              'temp': h.temperature,
              'pop': h.precipitationProbability,
              'precipitation': h.precipitation,
              'condition': h.condition.name,
            },
        ],
        'daily': [
          for (final d in forecast.daily.take(_days))
            {
              'date': toolDay(forecast.wallClock(d.date)),
              'condition': d.condition.name,
              'max': d.tempMax,
              'min': d.tempMin,
              'pop': d.precipitationProbabilityMax,
              'precipitation': d.precipitationSum,
            },
        ],
      }),
      summary: const ToolSummary(kind: ChatToolKind.weather, count: 1),
    );
  }
}
