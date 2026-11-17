import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/transit/prefs_transit_cache.dart';
import 'package:walk/domain/transit/entity/station_hit.dart';

class _TestClock extends Clock {
  _TestClock(this.t);
  DateTime t;
  @override
  DateTime now() => t;
}

StationHit _hit(String name) => StationHit(
  name: name,
  kind: StationKind.subway,
  lat: 37.5,
  lng: 127.0,
  detail: '2호선',
);

void main() {
  late SharedPreferences prefs;
  late _TestClock clock;
  late PrefsTransitCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    clock = _TestClock(DateTime(2026, 11, 17, 9));
    cache = PrefsTransitCache(prefs, clock);
  });

  test('routes expire after 10 minutes', () {
    cache.putRoutes('k', const []);
    final first = cache.routes('k');
    expect(first, isNotNull);
    expect(first!.fetchedAt, DateTime(2026, 11, 17, 9));

    clock.t = DateTime(2026, 11, 17, 9, 9, 59);
    expect(cache.routes('k'), isNotNull);

    clock.t = DateTime(2026, 11, 17, 9, 10);
    expect(cache.routes('k'), isNull);
    expect(cache.routes('other'), isNull);
  });

  test('stations expire after 7 days', () async {
    await cache.putStations('강남', [_hit('강남')]);
    clock.t = clock.t.add(const Duration(days: 7) - const Duration(seconds: 1));
    expect((await cache.stations('강남'))!.single.name, '강남');

    clock.t = DateTime(2026, 11, 17, 9).add(const Duration(days: 7));
    expect(await cache.stations('강남'), isNull);
  });

  test('stations survive a new cache instance (prefs backed)', () async {
    await cache.putStations('강남', [_hit('강남')]);
    final again = PrefsTransitCache(prefs, clock);
    expect((await again.stations('강남'))!.single.name, '강남');
  });

  test('query normalized (trim, lowercase, no spaces)', () async {
    await cache.putStations('  Seoul  Station ', [_hit('서울역')]);
    expect(await cache.stations('seoulstation'), isNotNull);
    expect(await cache.stations('SEOUL STATION'), isNotNull);
    expect(await cache.stations('seoul'), isNull);
  });

  test('station cache keeps newest 100', () async {
    for (var i = 0; i < 101; i++) {
      clock.t = clock.t.add(const Duration(seconds: 1));
      await cache.putStations('q$i', [_hit('s$i')]);
    }
    expect(await cache.stations('q0'), isNull);
    expect(await cache.stations('q1'), isNotNull);
    expect(await cache.stations('q100'), isNotNull);
  });

  test('broken stored json reads as miss', () async {
    await prefs.setString('transit.stationCache', '{not json');
    expect(await cache.stations('x'), isNull);
    await cache.putStations('x', [_hit('x')]);
    expect(await cache.stations('x'), isNotNull);
  });
}
