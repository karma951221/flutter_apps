import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/alarm/channel_alarm_sound_source.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/domain/alarm/sound/alarm_sound_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelAlarmSoundSource.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void answer(Object? Function(MethodCall call) reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  void fail(String method) => answer((call) {
    if (call.method == method)
      throw PlatformException(code: 'failed', message: 'boom');
    return null;
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('채널 이름은 walk/alarm_sounds', () {
    expect(ChannelAlarmSoundSource.channelName, 'walk/alarm_sounds');
  });

  group('deviceRingtones', () {
    test('list 응답을 제목 · uri 로 옮긴다', () async {
      answer(
        (_) => [
          {'title': 'Morning', 'uri': 'content://media/internal/audio/media/1'},
          {'title': 'Bell', 'uri': 'content://media/internal/audio/media/2'},
        ],
      );

      final ringtones = await ChannelAlarmSoundSource().deviceRingtones();

      expect(calls.single.method, 'list');
      expect(ringtones, [
        (title: 'Morning', uri: 'content://media/internal/audio/media/1'),
        (title: 'Bell', uri: 'content://media/internal/audio/media/2'),
      ]);
    });

    test('null 응답은 빈 목록', () async {
      answer((_) => null);
      expect(await ChannelAlarmSoundSource().deviceRingtones(), isEmpty);
    });

    test('오류는 AlarmSoundException', () async {
      fail('list');
      expect(
        ChannelAlarmSoundSource().deviceRingtones(),
        throwsA(isA<AlarmSoundException>()),
      );
    });

    test('채널이 없어도 AlarmSoundException', () async {
      expect(
        ChannelAlarmSoundSource().deviceRingtones(),
        throwsA(isA<AlarmSoundException>()),
      );
    });
  });

  group('preview', () {
    setUp(() => answer((_) => null));

    test('system 은 kind system', () async {
      await ChannelAlarmSoundSource().preview(const AlarmSound.system());
      expect(calls.single.method, 'preview');
      expect(calls.single.arguments, {'kind': 'system', 'value': null});
    });

    test('bundled 는 kind asset + 에셋 경로', () async {
      await ChannelAlarmSoundSource().preview(
        const AlarmSound.bundled(BundledAlarmSounds.chime),
      );
      expect(calls.single.arguments, {
        'kind': 'asset',
        'value': 'assets/alarm/chime.wav',
      });
    });

    test('uri 를 주면 소리와 상관없이 kind uri', () async {
      await ChannelAlarmSoundSource().preview(
        const AlarmSound.system(),
        uri: 'content://media/internal/audio/media/1',
      );
      expect(calls.single.arguments, {
        'kind': 'uri',
        'value': 'content://media/internal/audio/media/1',
      });
    });

    test('복사한 기기음은 파일 uri 로 튼다', () async {
      await ChannelAlarmSoundSource().preview(
        const AlarmSound.device(
          title: 'Bell',
          path: '/data/app_flutter/alarm_sounds/a.ogg',
        ),
      );
      expect(calls.single.arguments, {
        'kind': 'uri',
        'value': 'file:///data/app_flutter/alarm_sounds/a.ogg',
      });
    });

    test('오류는 AlarmSoundException', () async {
      fail('preview');
      expect(
        ChannelAlarmSoundSource().preview(const AlarmSound.system()),
        throwsA(isA<AlarmSoundException>()),
      );
    });
  });

  group('stopPreview', () {
    test('stopPreview 를 부른다', () async {
      answer((_) => null);
      await ChannelAlarmSoundSource().stopPreview();
      expect(calls.single.method, 'stopPreview');
    });

    test('채널이 없으면 조용히 끝난다', () async {
      await ChannelAlarmSoundSource().stopPreview();
    });
  });

  group('import', () {
    const ringtone = (
      title: 'Bell',
      uri: 'content://media/internal/audio/media/2',
    );

    test('uri 를 넘기고 돌려받은 경로로 AlarmSound.device', () async {
      answer((_) => '/data/app_flutter/alarm_sounds/abc.ogg');

      final sound = await ChannelAlarmSoundSource().import(ringtone);

      expect(calls.single.method, 'import');
      expect(calls.single.arguments, {
        'uri': 'content://media/internal/audio/media/2',
      });
      expect(
        sound,
        const AlarmSound.device(
          title: 'Bell',
          path: '/data/app_flutter/alarm_sounds/abc.ogg',
        ),
      );
    });

    test('오류는 AlarmSoundException', () async {
      fail('import');
      expect(
        ChannelAlarmSoundSource().import(ringtone),
        throwsA(isA<AlarmSoundException>()),
      );
    });

    test('경로가 비면 AlarmSoundException', () async {
      answer((_) => null);
      expect(
        ChannelAlarmSoundSource().import(ringtone),
        throwsA(isA<AlarmSoundException>()),
      );
    });
  });
}
