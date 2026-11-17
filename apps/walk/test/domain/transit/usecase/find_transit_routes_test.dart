import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/find_transit_routes.dart';
import 'package:walk/domain/transit/usecase/transit_api_key.dart';

import 'fakes.dart';

TransitPath _path(int total, {int transfers = 0}) => TransitPath(
  totalMinutes: total,
  transferCount: transfers,
  legs: const [],
);

const _a = TransitPoint(
  lat: 37.5,
  lng: 127.0,
  label: 'A',
  source: TransitPointSource.address,
);
const _b = TransitPoint(
  lat: 37.6,
  lng: 127.1,
  label: 'B',
  source: TransitPointSource.address,
);

void main() {
  late FixedClock clock;
  late FakeKeyStore store;
  late FakeRouteSource source;
  late FakeCache cache;
  late FindTransitRoutes find;

  setUp(() {
    clock = FixedClock(DateTime(2026, 11, 17, 9));
    store = FakeKeyStore(key: 'k');
    source = FakeRouteSource([_path(40), _path(20)]);
    cache = FakeCache(clock);
    find = FindTransitRoutes(
      source,
      cache,
      TransitApiKey(store, fallback: ''),
      store,
      clock,
    );
  });

  test('same pair within 10 minutes uses cache (source called once)', () async {
    final first = await find(_a, _b);
    clock.value = clock.value.add(const Duration(minutes: 5));
    final second = await find(_a, _b);
    expect(source.calls, 1);
    expect(first.fromCache, isFalse);
    expect(second.fromCache, isTrue);
    expect(second.fetchedAt, first.fetchedAt);
  });

  test('refresh skips cache', () async {
    await find(_a, _b);
    final again = await find(_a, _b, refresh: true);
    expect(source.calls, 2);
    expect(again.fromCache, isFalse);
  });

  test('missing key throws missingKey without calling source', () async {
    store.key = null;
    await expectLater(find(_a, _b), throwsA(isA<TransitMissingKey>()));
    expect(source.calls, 0);
  });

  test('keyRejected marks status rejected', () async {
    source.error = const TransitFailure.keyRejected('bad');
    await expectLater(find(_a, _b), throwsA(isA<TransitKeyRejected>()));
    expect(store.savedStatus, TransitKeyStatus.rejected);
  });

  test('success marks connected', () async {
    await find(_a, _b);
    expect(store.savedStatus, TransitKeyStatus.connected);
  });

  test('results sorted', () async {
    final r = await find(_a, _b);
    expect(r.paths.map((p) => p.totalMinutes), [20, 40]);
  });
}
