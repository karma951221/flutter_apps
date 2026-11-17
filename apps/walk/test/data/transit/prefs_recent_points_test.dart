import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/transit/prefs_recent_points.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';

TransitPoint _p(int i, {String? label}) => TransitPoint(
  lat: 37 + i / 100,
  lng: 127,
  label: label ?? 'p$i',
  source: TransitPointSource.station,
);

void main() {
  late SharedPreferences prefs;
  late PrefsRecentPoints recent;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    recent = PrefsRecentPoints(prefs);
  });

  test('empty by default', () async {
    expect(await recent.load(), isEmpty);
  });

  test('keeps 10 newest, dedupes by cacheKey', () async {
    for (var i = 0; i < 12; i++) {
      await recent.add(_p(i));
    }
    var list = await recent.load();
    expect(list, hasLength(10));
    expect(list.first.label, 'p11');
    expect(list.last.label, 'p2');

    await recent.add(_p(5, label: 'renamed'));
    list = await recent.load();
    expect(list, hasLength(10));
    expect(list.first.label, 'renamed');
    expect(list.where((p) => p.cacheKey == _p(5).cacheKey), hasLength(1));
  });

  test('persists in prefs and skips broken entries', () async {
    await recent.add(_p(1));
    expect(prefs.getString('transit.recent'), isNotNull);
    expect(await PrefsRecentPoints(prefs).load(), hasLength(1));

    await prefs.setString('transit.recent', '[{"x":1}, 3]');
    expect(await recent.load(), isEmpty);
    await prefs.setString('transit.recent', 'garbage');
    expect(await recent.load(), isEmpty);
  });
}
