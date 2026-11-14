import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/weather/prefs_weather_cache.dart';
import 'package:walk/domain/weather/weather_cache.dart';

Future<PrefsWeatherCache> _cache([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsWeatherCache(await SharedPreferences.getInstance());
}

void main() {
  test('비어 있으면 null', () async {
    final cache = await _cache();

    expect(await cache.read(), isNull);
  });

  test('쓰고 읽으면 같다', () async {
    final cache = await _cache();
    final value = CachedForecast(
      payload: '{"hourly":{}}',
      lat: 33.5,
      lng: 126.5,
      placeName: '애월읍',
      fetchedAt: DateTime.utc(2026, 11, 14, 3, 30),
    );

    await cache.write(value);

    final read = await cache.read();
    expect(read, value);
    expect(read!.fetchedAt.isUtc, isTrue);
  });

  test('장소 이름이 없어도 쓰고 읽는다', () async {
    final cache = await _cache();
    final value = CachedForecast(
      payload: 'x',
      lat: 1,
      lng: 2,
      fetchedAt: DateTime.utc(2026, 11, 14),
    );

    await cache.write(value);

    expect((await cache.read())!.placeName, isNull);
  });

  group('깨진 값은 null 이고 던지지 않는다', () {
    const key = PrefsWeatherCache.key;

    test('깨진 JSON', () async {
      final cache = await _cache({key: '{not json'});

      expect(await cache.read(), isNull);
    });

    test('필드 빠짐', () async {
      final cache = await _cache({key: '{"payload":"x","lat":1.0}'});

      expect(await cache.read(), isNull);
    });

    test('타입이 다름', () async {
      final cache = await _cache({
        key: '{"payload":1,"lat":"a","lng":2,"fetchedAt":"x"}',
      });

      expect(await cache.read(), isNull);
    });

    test('문자열이 아닌 값', () async {
      final cache = await _cache({key: 5});

      expect(await cache.read(), isNull);
    });
  });
}
