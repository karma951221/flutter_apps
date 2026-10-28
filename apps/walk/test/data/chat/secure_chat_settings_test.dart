import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/chat/secure_chat_settings.dart';

class _MockSecure extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecure secure;
  late SharedPreferences prefs;
  late SecureChatSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    secure = _MockSecure();
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(
      () => secure.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    settings = SecureChatSettings(secure, prefs);
  });

  test('키를 trim 해 보안 저장소에만 쓴다', () async {
    await settings.saveApiKey('  sk-ant-secret  ');

    verify(
      () => secure.write(key: 'anthropic_api_key', value: 'sk-ant-secret'),
    ).called(1);
    for (final k in prefs.getKeys()) {
      expect(prefs.get(k).toString(), isNot(contains('sk-ant-secret')));
    }
  });

  test('빈 키 저장은 삭제와 같다', () async {
    await settings.saveApiKey('   ');

    verify(() => secure.delete(key: 'anthropic_api_key')).called(1);
    verifyNever(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('저장 안 했거나 빈 값이면 apiKey 는 null', () async {
    expect(await settings.apiKey(), isNull);
    when(
      () => secure.read(key: 'anthropic_api_key'),
    ).thenAnswer((_) async => ' ');
    expect(await settings.apiKey(), isNull);
    when(
      () => secure.read(key: 'anthropic_api_key'),
    ).thenAnswer((_) async => 'k');
    expect(await settings.apiKey(), 'k');
  });

  test('동의는 prefs 에 남는다', () async {
    expect(settings.consented, isFalse);
    await settings.setConsented();

    expect(settings.consented, isTrue);
    expect(prefs.getBool('chat.consented'), isTrue);
  });
}
