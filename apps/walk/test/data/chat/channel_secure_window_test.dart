import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/channel_secure_window.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(
    () => messenger.setMockMethodCallHandler(ChannelSecureWindow.channel, null),
  );

  test('setSecure(true/false) 는 setSecure 를 그 값으로 부른다', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(ChannelSecureWindow.channel, (call) async {
      calls.add(call);
      return null;
    });

    await ChannelSecureWindow().setSecure(true);
    await ChannelSecureWindow().setSecure(false);

    expect(calls.map((c) => c.method), ['setSecure', 'setSecure']);
    expect(calls.map((c) => c.arguments), [true, false]);
  });

  test('핸들러가 없거나 PlatformException 이어도 던지지 않는다', () async {
    await ChannelSecureWindow().setSecure(true);

    messenger.setMockMethodCallHandler(
      ChannelSecureWindow.channel,
      (_) async => throw PlatformException(code: 'boom'),
    );
    await ChannelSecureWindow().setSecure(true);
  });
}
