import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/chat/secure_chat_settings.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

class _MockSecure extends Mock implements FlutterSecureStorage {}

class _MockPrefs extends Mock implements SharedPreferences {}

void main() {
  const key = 'sk-ant-api03-Ab3xQRSTuvwzSECRET';

  late _MockSecure secure;
  late SharedPreferences prefs;
  late SecureChatSettings settings;

  /// 보안 저장소의 내용. read · write · delete 가 이 맵을 본다.
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
    settings = SecureChatSettings(secure, prefs);
  });

  void expectNoKeyInPrefs(String text) {
    for (final k in prefs.getKeys()) {
      expect(prefs.get(k).toString(), isNot(contains(text)));
    }
  }

  test('connect 는 trim 한 키를 chat.apiKey 에만 쓰고 prefs 에 벤더 · 상태를 쓴다', () async {
    await settings.connect(
      ChatVendor.anthropic,
      '  $key  ',
      ChatKeyStatus.valid,
    );

    verify(() => secure.write(key: 'chat.apiKey', value: key)).called(1);
    expect(prefs.getString('chat.vendor'), 'anthropic');
    expect(prefs.getString('chat.keyStatus'), 'valid');
    expectNoKeyInPrefs(key);
    expectNoKeyInPrefs('QRST');
    expect(await settings.apiKey(), key);
  });

  test('connect 쓰기가 실패하면 벤더 · 상태가 그대로이고 예외를 던진다', () async {
    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.valid);
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenThrow(Exception('keystore'));

    await expectLater(
      settings.connect(
        ChatVendor.openai,
        'sk-proj-NewKeyValue',
        ChatKeyStatus.unverified,
      ),
      throwsException,
    );

    expect(prefs.getString('chat.vendor'), 'anthropic');
    expect(prefs.getString('chat.keyStatus'), 'valid');
    expect(await settings.apiKey(), key);
  });

  test('빈 키로 connect 하면 ArgumentError', () async {
    await expectLater(
      settings.connect(ChatVendor.anthropic, '   ', ChatKeyStatus.unverified),
      throwsArgumentError,
    );
    verifyNever(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('connection 은 미리보기 · 벤더 · 상태를 주고 원문이 없다', () async {
    expect(await settings.connection(), isNull);
    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.valid);

    final connection = await settings.connection();

    expect(
      connection,
      const ChatConnection(
        vendor: ChatVendor.anthropic,
        keyPreview: 'sk-ant-api03-Ab3x••••',
        status: ChatKeyStatus.valid,
      ),
    );
    expect(connection.toString(), isNot(contains('QRST')));
    expect(connection.toString(), isNot(contains('SECRET')));
    expect(await settings.hasApiKey(), isTrue);
  });

  test('옛 anthropic_api_key 를 chat.apiKey 로 옮기고 지운다', () async {
    stored['anthropic_api_key'] = key;

    final connection = await settings.connection();

    verifyInOrder([
      () => secure.write(key: 'chat.apiKey', value: key),
      () => secure.delete(key: 'anthropic_api_key'),
    ]);
    expect(stored.containsKey('anthropic_api_key'), isFalse);
    expect(connection?.vendor, ChatVendor.anthropic);
    expect(connection?.status, ChatKeyStatus.unverified);
    expect(prefs.getString('chat.vendor'), 'anthropic');
    expect(prefs.getString('chat.keyStatus'), 'unverified');
  });

  test('이전 쓰기가 실패하면 옛 키를 지우지 않는다', () async {
    stored['anthropic_api_key'] = key;
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenThrow(Exception('keystore'));

    expect(await settings.connection(), isNull);

    verifyNever(() => secure.delete(key: 'anthropic_api_key'));
    expect(stored['anthropic_api_key'], key);

    // 다음 접근 때 다시 옮긴다.
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((inv) async {
      stored[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String;
    });
    expect(await settings.hasApiKey(), isTrue);
    expect(stored.containsKey('anthropic_api_key'), isFalse);
  });

  test('옛 항목을 읽지 못하면 지우고 다시 시도하지 않는다', () async {
    stored['anthropic_api_key'] = key;
    when(
      () => secure.read(key: 'anthropic_api_key'),
    ).thenThrow(Exception('bad padding'));

    expect(await settings.connection(), isNull);
    expect(await settings.hasApiKey(), isFalse);

    verify(() => secure.read(key: 'anthropic_api_key')).called(1);
    verify(() => secure.delete(key: 'anthropic_api_key')).called(1);
    expect(stored.containsKey('anthropic_api_key'), isFalse);
  });

  test('disconnect 는 이전 못 한 옛 키도 지워 되살아나지 않는다', () async {
    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.valid);
    // 이전이 끝난 뒤 옛 항목이 남은 경우(예: 이전 실패 뒤 다시 연결).
    stored['anthropic_api_key'] = 'sk-ant-api03-OldKeyValue';

    await settings.disconnect();

    expect(stored.containsKey('anthropic_api_key'), isFalse);
    expect(await SecureChatSettings(secure, prefs).connection(), isNull);
  });

  test('disconnect 는 옛 키 지우기가 실패해도 끝난다', () async {
    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.valid);
    when(
      () => secure.delete(key: 'anthropic_api_key'),
    ).thenThrow(Exception('keystore'));

    await settings.disconnect();

    expect(stored.containsKey('chat.apiKey'), isFalse);
    expect(prefs.containsKey('chat.vendor'), isFalse);
  });

  test('읽기가 던지면 항목을 지우고 미연결', () async {
    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.valid);
    when(
      () => secure.read(key: 'chat.apiKey'),
    ).thenThrow(Exception('bad padding'));

    expect(await settings.connection(), isNull);
    expect(await settings.hasApiKey(), isFalse);
    expect(prefs.containsKey('chat.vendor'), isFalse);
    expect(prefs.containsKey('chat.keyStatus'), isFalse);
    verify(() => secure.delete(key: 'chat.apiKey')).called(greaterThan(0));
  });

  test('읽기가 던지고 지우기도 실패해도 미연결', () async {
    await prefs.setString('chat.vendor', 'anthropic');
    when(() => secure.read(key: 'chat.apiKey')).thenThrow(Exception('bad'));
    when(() => secure.delete(key: 'chat.apiKey')).thenThrow(Exception('bad'));

    expect(await settings.connection(), isNull);
    expect(prefs.containsKey('chat.vendor'), isFalse);
  });

  test('키 없이 prefs 만 남아 있으면(복원) 미연결로 정리한다', () async {
    await prefs.setString('chat.vendor', 'openai');
    await prefs.setString('chat.keyStatus', 'valid');

    expect(await settings.connection(), isNull);
    expect(prefs.containsKey('chat.vendor'), isFalse);
    expect(prefs.containsKey('chat.keyStatus'), isFalse);
  });

  test('키는 있는데 벤더가 없으면 키 모양으로 채우고 unverified', () async {
    stored['chat.apiKey'] = 'sk-proj-Ab3xQRSTuvwz';

    final connection = await settings.connection();

    expect(connection?.vendor, ChatVendor.openai);
    expect(connection?.status, ChatKeyStatus.unverified);
    expect(connection?.keyPreview, 'sk-proj-Ab3x••••');
    expect(prefs.getString('chat.vendor'), 'openai');

    // 모양을 모르면 anthropic.
    await prefs.remove('chat.vendor');
    stored['chat.apiKey'] = 'unknown-shape-key';
    expect((await settings.connection())?.vendor, ChatVendor.anthropic);
  });

  test('disconnect 는 키 · 벤더 · 상태를 지우고 동의는 남긴다', () async {
    await settings.setConsented();
    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.valid);

    await settings.disconnect();

    expect(stored.containsKey('chat.apiKey'), isFalse);
    expect(prefs.containsKey('chat.vendor'), isFalse);
    expect(prefs.containsKey('chat.keyStatus'), isFalse);
    expect(settings.consented, isTrue);
    expect(await settings.connection(), isNull);
  });

  test('setKeyStatus 는 연결돼 있을 때만, 같은 값이면 prefs 를 쓰지 않는다', () async {
    // 미연결 — 쓰지 않는다.
    await settings.setKeyStatus(ChatKeyStatus.invalid, forKey: key);
    expect(prefs.containsKey('chat.keyStatus'), isFalse);

    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.unverified);
    await settings.setKeyStatus(ChatKeyStatus.valid, forKey: key);
    expect((await settings.connection())?.status, ChatKeyStatus.valid);

    // 같은 값이면 prefs 쓰기가 없다.
    final mockPrefs = _MockPrefs();
    when(() => mockPrefs.getString('chat.vendor')).thenReturn('anthropic');
    when(() => mockPrefs.getString('chat.keyStatus')).thenReturn('valid');
    final quiet = SecureChatSettings(secure, mockPrefs);

    await quiet.setKeyStatus(ChatKeyStatus.valid, forKey: key);

    verifyNever(() => mockPrefs.setString(any(), any()));
  });

  test('setKeyStatus 는 저장된 키가 forKey 와 다르면 쓰지 않는다', () async {
    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.unverified);

    await settings.setKeyStatus(
      ChatKeyStatus.invalid,
      forKey: 'sk-ant-api03-OldKeyBeforeChange',
    );
    expect(prefs.getString('chat.keyStatus'), 'unverified');

    // 앞뒤 공백은 같은 키로 본다.
    await settings.setKeyStatus(ChatKeyStatus.valid, forKey: ' $key ');
    expect(prefs.getString('chat.keyStatus'), 'valid');
  });

  test('setKeyStatus 는 키를 읽지 못하면 쓰지 않고 던지지 않는다', () async {
    await settings.connect(ChatVendor.anthropic, key, ChatKeyStatus.unverified);
    when(
      () => secure.read(key: 'chat.apiKey'),
    ).thenThrow(Exception('keystore'));

    await settings.setKeyStatus(ChatKeyStatus.valid, forKey: key);

    expect(prefs.getString('chat.keyStatus'), isNot('valid'));
  });

  test('connect 가 키를 쓴 뒤 prefs 쓰기에 실패하면 상태를 지우고 던진다', () async {
    final mockPrefs = _MockPrefs();
    when(
      () => mockPrefs.setString('chat.vendor', any()),
    ).thenThrow(Exception('prefs'));
    when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
    final failing = SecureChatSettings(secure, mockPrefs);

    await expectLater(
      failing.connect(ChatVendor.anthropic, key, ChatKeyStatus.valid),
      throwsException,
    );

    expect(stored['chat.apiKey'], key);
    verify(() => mockPrefs.remove('chat.keyStatus')).called(1);
    verifyNever(() => mockPrefs.setString('chat.keyStatus', any()));
  });

  test('connect 의 prefs 쓰기 실패 뒤 상태 지우기도 실패하면 원래 예외를 던진다', () async {
    final mockPrefs = _MockPrefs();
    when(
      () => mockPrefs.setString(any(), any()),
    ).thenThrow(StateError('prefs'));
    when(() => mockPrefs.remove(any())).thenThrow(Exception('remove'));
    final failing = SecureChatSettings(secure, mockPrefs);

    await expectLater(
      failing.connect(ChatVendor.anthropic, key, ChatKeyStatus.valid),
      throwsStateError,
    );
  });

  test('동의는 prefs 에 남는다', () async {
    expect(settings.consented, isFalse);
    await settings.setConsented();

    expect(settings.consented, isTrue);
    expect(prefs.getBool('chat.consented'), isTrue);
  });
}
