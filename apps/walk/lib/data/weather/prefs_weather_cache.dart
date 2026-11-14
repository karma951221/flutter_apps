import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/weather/weather_cache.dart';

/// 마지막 예보를 JSON 한 줄로 둔다. 깨졌거나 필드가 빠지면 없는 것으로 본다.
@LazySingleton(as: WeatherCache)
class PrefsWeatherCache implements WeatherCache {
  PrefsWeatherCache(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'weather.cache.v1';

  @override
  Future<CachedForecast?> read() async {
    try {
      // getString 은 문자열이 아닌 값에서 던지므로 get 으로 읽는다.
      final raw = _prefs.get(key);
      if (raw is! String) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return CachedForecast(
        payload: json['payload'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        placeName: json['placeName'] as String?,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String).toUtc(),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(CachedForecast value) => _prefs.setString(
    key,
    jsonEncode({
      'payload': value.payload,
      'lat': value.lat,
      'lng': value.lng,
      'placeName': value.placeName,
      'fetchedAt': value.fetchedAt.toUtc().toIso8601String(),
    }),
  );
}
