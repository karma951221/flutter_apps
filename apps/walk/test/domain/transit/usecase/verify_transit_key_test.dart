import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/verify_transit_key.dart';

import 'fakes.dart';

void main() {
  late FakeKeyStore store;
  late FakeStationSearch remote;
  late VerifyTransitKey verify;

  setUp(() {
    store = FakeKeyStore();
    remote = FakeStationSearch();
    verify = VerifyTransitKey(remote, store);
  });

  test('success saves and returns connected', () async {
    final s = await verify('abc');
    expect(s, TransitKeyStatus.connected);
    expect(store.key, 'abc');
    expect(store.savedStatus, TransitKeyStatus.connected);
    expect(remote.lastKey, 'abc');
  });

  test('rejected key is not saved', () async {
    remote.error = const TransitFailure.keyRejected('bad');
    await expectLater(verify('abc'), throwsA(isA<TransitKeyRejected>()));
    expect(store.saveCalls, 0);
  });

  test('network with saveIfUnverified saves unverified', () async {
    remote.error = const TransitFailure.network();
    final s = await verify('abc', saveIfUnverified: true);
    expect(s, TransitKeyStatus.unverified);
    expect(store.savedStatus, TransitKeyStatus.unverified);
  });

  test('network without saveIfUnverified throws and does not save', () async {
    remote.error = const TransitFailure.network();
    await expectLater(verify('abc'), throwsA(isA<TransitNetwork>()));
    expect(store.saveCalls, 0);
  });

  test('server error (e.g. code -8) is not a key rejection', () async {
    remote.error = const TransitFailure.server('HTTP 200 · code -8 · 형식 오류');
    await expectLater(verify('abc'), throwsA(isA<TransitServer>()));
    expect(store.saveCalls, 0);

    final s = await verify('abc', saveIfUnverified: true);
    expect(s, TransitKeyStatus.unverified);
    expect(store.savedStatus, TransitKeyStatus.unverified);
  });

  test('quota exceeded is not saved', () async {
    remote.error = const TransitFailure.quotaExceeded(
      'code -1 · LimitExceeded',
    );
    await expectLater(verify('abc'), throwsA(isA<TransitQuotaExceeded>()));
    expect(store.saveCalls, 0);
  });
}
