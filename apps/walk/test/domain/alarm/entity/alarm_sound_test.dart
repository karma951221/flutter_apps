import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';

void main() {
  AlarmSound roundTrip(AlarmSound sound) =>
      AlarmSound.fromJson(jsonDecode(jsonEncode(sound.toJson())));

  group('JSON 왕복', () {
    test('system', () {
      const sound = AlarmSound.system();

      expect(sound.toJson(), {'type': 'system'});
      expect(roundTrip(sound), sound);
    });

    test('bundled', () {
      const sound = AlarmSound.bundled(BundledAlarmSounds.chime);

      expect(sound.toJson(), {'type': 'bundled', 'asset': 'assets/alarm/chime.wav'});
      expect(roundTrip(sound), sound);
    });

    test('device', () {
      const sound = AlarmSound.device(
        title: 'Morning Glory',
        path: '/data/user/0/com.karma.walk/app_flutter/alarm_sounds/1a2b.ogg',
      );

      expect(sound.toJson(), {
        'type': 'device',
        'title': 'Morning Glory',
        'path': '/data/user/0/com.karma.walk/app_flutter/alarm_sounds/1a2b.ogg',
      });
      expect(roundTrip(sound), sound);
    });
  });

  group('fromJson 은 읽지 못하면 system 으로 읽는다(던지지 않는다)', () {
    const system = AlarmSound.system();

    test('값이 없다', () {
      expect(AlarmSound.fromJson(null), system);
    });

    test('모르는 type', () {
      expect(AlarmSound.fromJson(const {'type': 'music', 'path': '/sdcard/a.mp3'}), system);
    });

    test('type 이 없다', () {
      expect(AlarmSound.fromJson(const {'asset': BundledAlarmSounds.chime}), system);
    });

    test('맵이 아니다', () {
      expect(AlarmSound.fromJson('bundled'), system);
      expect(AlarmSound.fromJson(const ['system']), system);
    });

    test('bundled 의 asset 이 없거나 문자열이 아니다', () {
      expect(AlarmSound.fromJson(const {'type': 'bundled'}), system);
      expect(AlarmSound.fromJson(const {'type': 'bundled', 'asset': 3}), system);
    });

    test('device 의 title · path 가 없거나 문자열이 아니다', () {
      expect(AlarmSound.fromJson(const {'type': 'device', 'title': 'A'}), system);
      expect(AlarmSound.fromJson(const {'type': 'device', 'path': '/a.ogg'}), system);
      expect(AlarmSound.fromJson(const {'type': 'device', 'title': 1, 'path': '/a.ogg'}), system);
    });
  });

  group('BundledAlarmSounds', () {
    test('기존 비프는 이미 걸린 회차가 울리도록 default.wav 이름 그대로다', () {
      expect(BundledAlarmSounds.beep, 'assets/alarm/default.wav');
      expect(BundledAlarmSounds.all, [
        BundledAlarmSounds.beep,
        BundledAlarmSounds.chime,
        BundledAlarmSounds.rising,
      ]);
    });

    // 패키지가 loopAudio 로 반복하므로 모두 같은 형식의 3초 클립이다.
    for (final asset in BundledAlarmSounds.all) {
      test('$asset 은 번들에 있는 22.05kHz 모노 16bit 3초 WAV 다', () async {
        TestWidgetsFlutterBinding.ensureInitialized();

        final bytes = await rootBundle.load(asset);
        final header = _WavHeader.parse(bytes);

        expect(header.channels, 1);
        expect(header.sampleRate, 22050);
        expect(header.bitsPerSample, 16);
        expect(header.seconds, closeTo(3.0, 0.01));
      });
    }
  });
}

/// RIFF/WAVE 헤더에서 fmt · data 청크만 읽는다.
class _WavHeader {
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final double seconds;

  const _WavHeader(this.channels, this.sampleRate, this.bitsPerSample, this.seconds);

  static _WavHeader parse(ByteData bytes) {
    String tag(int offset) =>
        String.fromCharCodes([for (var i = 0; i < 4; i++) bytes.getUint8(offset + i)]);

    expect(tag(0), 'RIFF');
    expect(tag(8), 'WAVE');
    int? channels, sampleRate, bitsPerSample, dataSize;
    var offset = 12;
    while (offset + 8 <= bytes.lengthInBytes) {
      final id = tag(offset);
      final size = bytes.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (id == 'fmt ') {
        expect(bytes.getUint16(body, Endian.little), 1, reason: 'PCM');
        channels = bytes.getUint16(body + 2, Endian.little);
        sampleRate = bytes.getUint32(body + 4, Endian.little);
        bitsPerSample = bytes.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        dataSize = size;
      }
      offset = body + size + size % 2;
    }
    final frameBytes = channels! * bitsPerSample! ~/ 8;
    return _WavHeader(channels, sampleRate!, bitsPerSample, dataSize! / frameBytes / sampleRate);
  }
}
