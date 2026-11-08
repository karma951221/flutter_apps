import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/location/channel_location_recorder.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelLocationRecorder.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  const recorder = ChannelLocationRecorder();

  void answer(Object? Function(MethodCall call) reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('채널 이름', () {
    expect(
      ChannelLocationRecorder.channelName,
      'com.karma.walk/location_record',
    );
  });

  group('status', () {
    test('off', () async {
      answer(
        (_) => {'state': 'off', 'mode': 'normal', 'stillDetection': false},
      );
      expect(await recorder.status(), const RecorderStatus.off());
    });

    test('running 은 모드와 정지 감지를 싣는다', () async {
      answer(
        (_) => {'state': 'running', 'mode': 'dense', 'stillDetection': true},
      );
      expect(
        await recorder.status(),
        const RecorderStatus.running(RecordMode.dense, stillDetection: true),
      );
    });

    test('blocked', () async {
      answer(
        (_) => {'state': 'blocked', 'mode': 'normal', 'stillDetection': false},
      );
      expect(
        await recorder.status(),
        const RecorderStatus.blocked(RecordMode.normal),
      );
    });
  });

  group('start / stop / setMode', () {
    test('start(dense) 는 {"mode": "dense"} 를 보낸다', () async {
      answer((_) => null);
      await recorder.start(RecordMode.dense);
      expect(calls.single.method, 'start');
      expect(calls.single.arguments, {'mode': 'dense'});
    });

    test('stop 과 setMode', () async {
      answer((_) => null);
      await recorder.stop();
      await recorder.setMode(RecordMode.normal);
      expect(calls.map((c) => c.method), ['stop', 'setMode']);
      expect(calls.last.arguments, {'mode': 'normal'});
    });
  });

  group('drain / ack', () {
    test('drain 은 limit 을 보내고 점을 해석한다', () async {
      answer(
        (_) => [
          {
            'id': 1,
            't': 1700000000000,
            'lat': 37.5,
            'lng': 127.0,
            'acc': 12.5,
            'mode': 'normal',
            'still': false,
          },
          {
            'id': 2,
            't': 1700000180000,
            'lat': 37.6,
            'lng': 127.1,
            'acc': null,
            'mode': 'dense',
            'still': true,
          },
        ],
      );

      final rows = await recorder.drain(limit: 50);

      expect(calls.single.method, 'drain');
      expect(calls.single.arguments, {'limit': 50});
      expect(rows.map((r) => r.id), [1, 2]);
      final first = rows[0].point;
      expect(
        first.recordedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
      expect(first.recordedAt.isUtc, isTrue);
      expect(first.accuracyM, 12.5);
      expect(first.stillStart, isFalse);
      final second = rows[1].point;
      expect(second.accuracyM, isNull);
      expect(second.mode, RecordMode.dense);
      expect(second.stillStart, isTrue);
    });

    test('null 응답은 빈 목록', () async {
      answer((_) => null);
      expect(await recorder.drain(), isEmpty);
      expect(calls.single.arguments, {'limit': 2000});
    });

    test('ack 는 upToId 를 보낸다', () async {
      answer((_) => null);
      await recorder.ack(7);
      expect(calls.single.method, 'ack');
      expect(calls.single.arguments, {'upToId': 7});
    });

    test('clearInbox 는 인자 없이 채널을 부른다', () async {
      answer((_) => null);
      await recorder.clearInbox();
      expect(calls.single.method, 'clearInbox');
      expect(calls.single.arguments, isNull);
    });

    test('openBatterySettings 는 인자 없이 채널을 부른다', () async {
      answer((_) => null);
      await recorder.openBatterySettings();
      expect(calls.single.method, 'openBatterySettings');
      expect(calls.single.arguments, isNull);
    });
  });
}
