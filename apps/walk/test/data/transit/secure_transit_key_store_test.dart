import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/transit/secure_transit_key_store.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';

class _MockSecure extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecure secure;
  late SharedPreferences prefs;
  late SecureTransitKeyStore store;
  late Map<String, String> stored;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    secure = _MockSecure();
    stored = {};
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((inv) async {
      stored[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String;
    });
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((inv) async {
      stored.remove(inv.namedArguments[#key] as String);
    });
    when(
      () => secure.read(key: any(named: 'key')),
    ).thenAnswer((inv) async => stored[inv.namedArguments[#key] as String]);
    store = SecureTransitKeyStore(secure, prefs);
  });

  test(
    'save writes trimmed key to secure storage only, then read returns it',
    () async {
      await store.save('  abc  ', TransitKeyStatus.connected);

      expect(stored, {'transit.odsayKey': 'abc'});
      expect(await store.read(), 'abc');
      for (final k in prefs.getKeys()) {
        expect(prefs.get(k).toString(), isNot(contains('abc')));
      }
    },
  );

  test('status persisted in prefs', () async {
    await store.save('abc', TransitKeyStatus.unverified);
    expect(prefs.getString('transit.keyStatus'), 'unverified');
    expect(await store.status(), TransitKeyStatus.unverified);

    await store.setStatus(TransitKeyStatus.rejected);
    expect(await store.status(), TransitKeyStatus.rejected);
  });

  test('delete removes key and status', () async {
    await store.save('abc', TransitKeyStatus.connected);
    await store.delete();

    expect(await store.read(), isNull);
    expect(await store.status(), isNull);
    expect(prefs.containsKey('transit.keyStatus'), isFalse);
  });

  test(
    'status without a stored key reads as null (restored prefs only)',
    () async {
      await prefs.setString('transit.keyStatus', 'connected');
      expect(await store.status(), isNull);
    },
  );

  test('unreadable keystore reads as no key', () async {
    when(() => secure.read(key: any(named: 'key'))).thenThrow(Exception('x'));
    expect(await store.read(), isNull);
  });

  test('blank key is rejected', () async {
    expect(
      () => store.save('   ', TransitKeyStatus.connected),
      throwsArgumentError,
    );
  });

  test('changes fires on save and delete, not on setStatus', () async {
    var count = 0;
    final sub = store.changes.listen((_) => count++);
    addTearDown(sub.cancel);

    await store.save('abc', TransitKeyStatus.connected);
    await pumpEventQueue();
    expect(count, 1);

    await store.setStatus(TransitKeyStatus.rejected);
    await pumpEventQueue();
    expect(count, 1);

    await store.delete();
    await pumpEventQueue();
    expect(count, 2);
  });
}
