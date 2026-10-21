// 포크 내부(`src/`)의 pigeon 채널 · 테스트 리셋을 쓴다.
// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:alarm/src/alarm_trigger_api_impl.dart';
import 'package:alarm/src/generated/platform_bindings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 포크 `Alarm` 의 호스트 콜백(`alarmRang` · `_alarmStopped`)과 Dart 대체 타이머
/// (`src/platform_timers.dart`). 포크 자체의 `flutter test` 는 돌리지 않으므로 앱 테스트에서 확인한다(FORK.md).
///
/// 앱에서 건 알람은 Dart 대체 타이머도 함께 건다. 앱이 백그라운드로 가면 타이머만 지우고 포그라운드
/// 구독은 남기는데, 포그라운드로 돌아올 때 호스트가 "안 울림" 이라 하면 지난 시각으로 타이머를 다시 걸어
/// 곧바로 `alarmRang` 을 부른다. 그래서 백그라운드에서 울리고 알림으로 끈 알람이 앱을 열면 다시 "울림" 이
/// 되어 울림 화면이 다시 떴다(에뮬레이터 QA, 2026-10-08).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prefix = 'dev.flutter.pigeon.alarm.AlarmApi.';
  const methods = ['getPendingAlarmEvents', 'setAlarm', 'stopAlarm', 'isRinging'];
  late Set<int> ringing;

  void install() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in methods) {
      messenger.setMockDecodedMessageHandler<Object?>(
        BasicMessageChannel<Object?>('$prefix$name', AlarmApi.pigeonChannelCodec),
        (message) async {
          final args = message as List<Object?>?;
          return switch (name) {
            'getPendingAlarmEvents' => <Object?>[<AlarmEventWire>[]],
            'isRinging' => <Object?>[
              switch (args?[0]) {
                final int id => ringing.contains(id),
                _ => ringing.isNotEmpty,
              },
            ],
            _ => <Object?>[null],
          };
        },
      );
    }
  }

  void remove() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in methods) {
      messenger.setMockDecodedMessageHandler<Object?>(
        BasicMessageChannel<Object?>('$prefix$name', AlarmApi.pigeonChannelCodec),
        null,
      );
    }
  }

  /// 호스트가 `AlarmTriggerApi` 를 부른 것처럼 보낸다.
  Future<void> fromHost(String method, int id) async {
    final completer = Completer<void>();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'dev.flutter.pigeon.alarm.AlarmTriggerApi.$method',
      AlarmTriggerApi.pigeonChannelCodec.encodeMessage(<Object?>[id]),
      (_) => completer.complete(),
    );
    await completer.future;
  }

  void lifecycle(List<AppLifecycleState> states) {
    for (final state in states) {
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(state);
    }
  }

  AlarmSettings alarm(int id, DateTime at) => AlarmSettings(
    id: id,
    dateTime: at,
    volumeSettings: VolumeSettings.fixed(),
    notificationSettings: const NotificationSettings(title: '알람', body: ''),
    allowSameSecondScheduling: true,
  );

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Alarm.resetForTesting();
    AlarmStorage.resetForTesting();
    AlarmTriggerApiImpl.resetForTesting();
    ringing = {};
    install();
    lifecycle([AppLifecycleState.resumed]);
    await Alarm.init();
  });

  tearDown(() {
    lifecycle([AppLifecycleState.resumed]);
    remove();
    Alarm.resetForTesting();
    AlarmStorage.resetForTesting();
    AlarmTriggerApiImpl.resetForTesting();
    debugDefaultTargetPlatformOverride = null;
  });

  test('백그라운드에서 울리고 알림으로 끈 알람은 앱으로 돌아와도 다시 울림이 되지 않는다', () async {
    await Alarm.set(alarmSettings: alarm(42, DateTime.now().add(const Duration(milliseconds: 300))));

    // 홈 화면으로 — 대체 타이머는 지워지고 포그라운드 구독만 남는다.
    lifecycle([AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    ringing.add(42);
    await fromHost('alarmRang', 42);
    expect(Alarm.ringing.value.containsId(42), isTrue);

    // 헤드업 알림의 [알람 끄기].
    ringing.remove(42);
    await fromHost('alarmStopped', 42);
    expect(Alarm.ringing.value.containsId(42), isFalse);

    lifecycle([AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    // 대체 타이머 주기(200ms) + 호스트를 기다리는 유예(700ms)보다 넉넉히.
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    expect(Alarm.ringing.value.containsId(42), isFalse);
  });

  test('울림 소식 없이 끔만 받은 알람도 앱으로 돌아와 다시 울림이 되지 않는다', () async {
    await Alarm.set(alarmSettings: alarm(42, DateTime.now().add(const Duration(milliseconds: 300))));
    lifecycle([AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // 울림 콜백이 이 엔진에 닿지 않았어도(다른 엔진이 받음) 끔은 온다.
    await fromHost('alarmStopped', 42);

    lifecycle([AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    expect(Alarm.ringing.value.containsId(42), isFalse);
  });

  test('백그라운드에서 호스트가 울린 알람은 끄기 전에 돌아와도 한 번만 울림이 된다', () async {
    final emitted = <bool>[];
    final sub = Alarm.ringing.listen((set) => emitted.add(set.containsId(42)));
    await Alarm.set(alarmSettings: alarm(42, DateTime.now().add(const Duration(milliseconds: 300))));
    lifecycle([AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    ringing.add(42);
    await fromHost('alarmRang', 42);

    lifecycle([AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await sub.cancel();

    expect(Alarm.ringing.value.containsId(42), isTrue);
    // 울림 → (호스트) 한 번. 다시 울림으로 바뀌는 값이 더 오지 않는다.
    expect(emitted.where((r) => r).length, 1);
  });
}
