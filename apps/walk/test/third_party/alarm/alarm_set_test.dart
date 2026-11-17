// 포크 내부(`src/`)의 pigeon 채널 · 테스트 리셋을 쓴다.
// ignore_for_file: implementation_imports
import 'package:alarm/alarm.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:alarm/src/alarm_trigger_api_impl.dart';
import 'package:alarm/src/generated/platform_bindings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 포크 `Alarm.set`(`third_party/alarm/lib/alarm.dart`)이 울리는 알람을 같은 id 로 다시 걸 때.
/// 포크 자체의 `flutter test` 는 돌리지 않으므로 앱 테스트에서 확인한다(FORK.md).
///
/// 울리는 알람을 같은 id 로 다시 거는 것은 스누즈다. 먼저 `stopAlarm` 을 부르면 네이티브가
/// 그 회차를 "끔" 으로 기록하므로(`AlarmService.handleStopAlarmCommand`), 네이티브의 같은 id
/// 교체(`AlarmApiImpl.clearForReplace` → `silenceRing`, "스누즈" 로 기록)에 맡겨야 한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prefix = 'dev.flutter.pigeon.alarm.AlarmApi.';
  const methods = [
    'getPendingAlarmEvents',
    'setAlarm',
    'stopAlarm',
    'isRinging',
  ];
  late List<String> calls;
  late Set<int> ringing;

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in methods) {
      messenger.setMockDecodedMessageHandler<Object?>(
        BasicMessageChannel<Object?>(
          '$prefix$name',
          AlarmApi.pigeonChannelCodec,
        ),
        (message) async {
          calls.add(name);
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
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in methods) {
      messenger.setMockDecodedMessageHandler<Object?>(
        BasicMessageChannel<Object?>(
          '$prefix$name',
          AlarmApi.pigeonChannelCodec,
        ),
        null,
      );
    }
  }

  AlarmSettings alarm(int id, DateTime at) => AlarmSettings(
    id: id,
    dateTime: at,
    volumeSettings: VolumeSettings.fixed(),
    notificationSettings: const NotificationSettings(title: '알람', body: ''),
    allowSameSecondScheduling: true,
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Alarm.resetForTesting();
    AlarmStorage.resetForTesting();
    AlarmTriggerApiImpl.resetForTesting();
    calls = [];
    ringing = {};
    install();
  });

  tearDown(() {
    remove();
    Alarm.resetForTesting();
    AlarmStorage.resetForTesting();
    AlarmTriggerApiImpl.resetForTesting();
    debugDefaultTargetPlatformOverride = null;
  });

  test('울리는 알람을 같은 id 로 다시 걸면 stopAlarm 없이 네이티브 교체에 맡긴다', () async {
    final now = DateTime.now();
    await AlarmStorage.saveAlarm(
      alarm(42, now.subtract(const Duration(minutes: 1))),
    );
    ringing.add(42);
    final snoozedTo = now.add(const Duration(minutes: 5));

    await Alarm.set(alarmSettings: alarm(42, snoozedTo));

    expect(calls, contains('setAlarm'));
    expect(calls, isNot(contains('stopAlarm')));
    expect((await Alarm.getAlarm(42))?.dateTime, snoozedTo);
    expect(Alarm.scheduled.value.alarms.single.dateTime, snoozedTo);
  });

  test('울리지 않는 알람을 같은 id 로 다시 걸면 예전처럼 먼저 멈춘다', () async {
    final now = DateTime.now();
    await AlarmStorage.saveAlarm(alarm(42, now.add(const Duration(hours: 1))));

    await Alarm.set(
      alarmSettings: alarm(42, now.add(const Duration(hours: 2))),
    );

    expect(calls, containsAllInOrder(['stopAlarm', 'setAlarm']));
  });
}
