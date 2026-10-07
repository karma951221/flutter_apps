import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/alarm/channel_next_alarm_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelNextAlarmWidget.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  const widget = ChannelNextAlarmWidget();

  void answer(Object? Function(MethodCall call) reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final tuesday7 = DateTime(2026, 9, 29, 7);
  final wednesday7 = DateTime(2026, 9, 30, 7);

  test('채널 이름은 walk/widget', () {
    expect(ChannelNextAlarmWidget.channelName, 'walk/widget');
  });

  group('show', () {
    test('update 에 회차들을 {atMillis, title} 목록으로 넘긴다', () async {
      answer((_) => null);

      await widget.show([
        (at: tuesday7, title: '출근'),
        (at: wednesday7, title: ''),
      ]);

      expect(calls.single.method, 'update');
      expect(calls.single.arguments, {
        'rings': [
          {'atMillis': tuesday7.millisecondsSinceEpoch, 'title': '출근'},
          {'atMillis': wednesday7.millisecondsSinceEpoch, 'title': ''},
        ],
      });
    });

    test('빈 목록도 넘긴다(예정된 알람 없음)', () async {
      answer((_) => null);

      await widget.show(const []);

      expect(calls.single.arguments, {'rings': <Object?>[]});
    });

    test('채널이 없으면 무시, 네이티브 오류는 던진다', () async {
      await widget.show([(at: tuesday7, title: '')]);

      answer((_) => throw PlatformException(code: 'failed'));
      await expectLater(
        widget.show(const []),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('takeLaunch', () {
    test('네이티브 응답을 돌려준다', () async {
      answer((_) => true);
      expect(await widget.takeLaunch(), isTrue);
      expect(calls.single.method, 'takeLaunch');

      answer((_) => false);
      expect(await widget.takeLaunch(), isFalse);
    });

    test('채널이 없거나 null 이면 false', () async {
      expect(await widget.takeLaunch(), isFalse);

      answer((_) => null);
      expect(await widget.takeLaunch(), isFalse);
    });
  });
}
