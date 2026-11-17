import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/usecase/transit_api_key.dart';

class _MockStore extends Mock implements TransitKeyStore {}

void main() {
  late _MockStore store;
  setUp(() => store = _MockStore());

  test('store beats fallback', () async {
    when(() => store.read()).thenAnswer((_) async => 'saved');
    expect(await TransitApiKey(store, fallback: 'env').current(), 'saved');
  });

  test('fallback used when store empty', () async {
    when(() => store.read()).thenAnswer((_) async => null);
    expect(await TransitApiKey(store, fallback: 'env').current(), 'env');
    when(() => store.read()).thenAnswer((_) async => '  ');
    expect(await TransitApiKey(store, fallback: 'env').current(), 'env');
  });

  test('blank fallback is null', () async {
    when(() => store.read()).thenAnswer((_) async => null);
    expect(await TransitApiKey(store, fallback: '').current(), isNull);
    expect(await TransitApiKey(store, fallback: '  ').current(), isNull);
  });
}
