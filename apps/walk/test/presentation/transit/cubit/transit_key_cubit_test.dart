import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/verify_transit_key.dart';
import 'package:walk/presentation/transit/cubit/transit_key_cubit.dart';

import '../../../domain/transit/usecase/fakes.dart';

void main() {
  late FakeKeyStore store;
  late FakeStationSearch remote;
  late TransitKeyCubit cubit;

  setUp(() {
    store = FakeKeyStore();
    remote = FakeStationSearch();
    cubit = TransitKeyCubit(store, VerifyTransitKey(remote, store));
  });

  tearDown(() => cubit.close());

  test('load without a key leaves preview empty', () async {
    await cubit.load();
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.keyPreview, isNull);
    expect(cubit.state.status, isNull);
  });

  test('load with a saved key masks it', () async {
    store
      ..key = 'abcd1234efgh5678'
      ..savedStatus = TransitKeyStatus.connected;
    await cubit.load();
    expect(cubit.state.keyPreview, 'abcd••••');
    expect(cubit.state.status, TransitKeyStatus.connected);
  });

  test('save connected', () async {
    await cubit.load();
    final r = await cubit.save('abcd1234efgh5678');
    expect(r, TransitKeySave.connected);
    expect(cubit.state.status, TransitKeyStatus.connected);
    expect(cubit.state.keyPreview, 'abcd••••');
    expect(cubit.state.busy, isFalse);
  });

  test('rejected keeps the server message and does not save', () async {
    remote.error = const TransitFailure.keyRejected('apiKey 오류');
    await cubit.load();
    final r = await cubit.save('abcd1234efgh5678');
    expect(r, TransitKeySave.rejected);
    expect(cubit.state.failure, const TransitFailure.keyRejected('apiKey 오류'));
    expect(store.saveCalls, 0);
    expect(cubit.state.keyPreview, isNull);
  });

  test('clearFailure drops the failure', () async {
    remote.error = const TransitFailure.keyRejected('bad');
    await cubit.save('abcd1234efgh5678');
    cubit.clearFailure();
    expect(cubit.state.failure, isNull);
  });

  test('network is reported without saving, then saved unverified', () async {
    remote.error = const TransitFailure.network('SocketException: nope');
    expect(await cubit.save('abcd1234efgh5678'), TransitKeySave.network);
    expect(store.saveCalls, 0);
    expect(
      cubit.state.failure,
      const TransitFailure.network('SocketException: nope'),
    );

    final r = await cubit.save('abcd1234efgh5678', saveIfUnverified: true);
    expect(r, TransitKeySave.unverified);
    expect(cubit.state.status, TransitKeyStatus.unverified);
    expect(store.savedStatus, TransitKeyStatus.unverified);
    expect(cubit.state.failure, isNull);
  });

  test('other failures are failed and keep their cause', () async {
    remote.error = const TransitFailure.quotaExceeded('code -1 · Limit');
    expect(await cubit.save('abcd1234efgh5678'), TransitKeySave.failed);
    expect(store.saveCalls, 0);
    expect(
      cubit.state.failure,
      const TransitFailure.quotaExceeded('code -1 · Limit'),
    );
  });

  test('storage failure becomes unexpected with type and message', () async {
    store.saveError = StateError('keystore locked');
    expect(await cubit.save('abcd1234efgh5678'), TransitKeySave.failed);
    expect(
      cubit.state.failure,
      const TransitFailure.unexpected('StateError: Bad state: keystore locked'),
    );
  });

  test('unexpected detail never shows the key', () async {
    store.saveError = StateError('could not write abcd1234efgh5678');
    await cubit.save('abcd1234efgh5678');
    expect(cubit.state.failure!.detail, isNot(contains('abcd1234')));
  });

  test('successful save clears an earlier failure', () async {
    remote.error = const TransitFailure.keyRejected('bad');
    await cubit.save('abcd1234efgh5678');
    remote.error = null;
    await cubit.save('abcd1234efgh5678');
    expect(cubit.state.failure, isNull);
  });

  test('delete clears the key and preview', () async {
    store
      ..key = 'abcd1234efgh5678'
      ..savedStatus = TransitKeyStatus.connected;
    await cubit.load();
    expect(await cubit.delete(), isTrue);
    expect(store.key, isNull);
    expect(cubit.state.keyPreview, isNull);
    expect(cubit.state.status, isNull);
  });
}
