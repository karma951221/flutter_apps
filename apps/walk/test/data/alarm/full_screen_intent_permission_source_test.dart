import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission/permission.dart';
import 'package:walk/data/alarm/full_screen_intent_permission_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(FullScreenIntentPermissionSource.channelName);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;

  void answer({required bool canUse}) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'canUse' ? canUse : null;
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('canUse 가 true 면 허용', () async {
    answer(canUse: true);
    expect(await FullScreenIntentPermissionSource().check(), PermissionStatus.granted);
  });

  test('canUse 가 false 면 거부', () async {
    answer(canUse: false);
    expect(await FullScreenIntentPermissionSource().check(), PermissionStatus.denied);
  });

  test('request 는 설정 화면을 열고 상태를 다시 읽는다', () async {
    answer(canUse: false);

    final status = await FullScreenIntentPermissionSource().request();

    expect(calls, ['openSettings', 'canUse']);
    expect(status, PermissionStatus.denied);
  });

  test('채널이 없으면 허용으로 본다', () async {
    expect(await FullScreenIntentPermissionSource().check(), PermissionStatus.granted);
  });
}
