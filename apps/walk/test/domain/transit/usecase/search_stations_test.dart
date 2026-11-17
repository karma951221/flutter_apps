import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/entity/station_hit.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/search_stations.dart';
import 'package:walk/domain/transit/usecase/transit_api_key.dart';

import 'fakes.dart';

const _hit = StationHit(
  name: '서울역',
  kind: StationKind.subway,
  lat: 37.55,
  lng: 126.97,
  detail: '1호선',
);

void main() {
  late FakeKeyStore store;
  late FakeStationSearch remote;
  late FakeCache cache;
  late SearchStations search;

  setUp(() {
    store = FakeKeyStore(key: 'k');
    remote = FakeStationSearch([_hit]);
    cache = FakeCache(FixedClock(DateTime(2026)));
    search = SearchStations(remote, cache, TransitApiKey(store, fallback: ''));
  });

  test('1 char → no call', () async {
    expect(await search(' 서 '), isEmpty);
    expect(remote.calls, 0);
  });

  test('cached query → no call', () async {
    await search('서울역');
    final again = await search('서울역');
    expect(remote.calls, 1);
    expect(again, [_hit]);
  });

  test('missing key throws missingKey', () async {
    store.key = null;
    await expectLater(search('서울역'), throwsA(isA<TransitMissingKey>()));
    expect(remote.calls, 0);
  });
}
