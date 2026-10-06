import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/alarm/entity/alarm_sound.dart';
import '../../domain/alarm/sound/alarm_sound_source.dart';

/// MainActivity 의 `AlarmSoundsChannel.kt` 로 기기 알람음을 다룬다.
@LazySingleton(as: AlarmSoundSource)
class ChannelAlarmSoundSource implements AlarmSoundSource {
  static const channelName = 'walk/alarm_sounds';
  static const _channel = MethodChannel(channelName);

  @override
  Future<List<DeviceRingtone>> deviceRingtones() async {
    final rows = await _invoke<List<Object?>>('list');
    return [
      for (final row in rows ?? const <Object?>[])
        if (row case {'title': final String title, 'uri': final String uri}) (title: title, uri: uri),
    ];
  }

  @override
  Future<void> preview(AlarmSound sound, {String? uri}) {
    final (kind, value) = uri != null
        ? ('uri', uri)
        : switch (sound) {
            SystemAlarmSound() => ('system', null),
            BundledAlarmSound(:final asset) => ('asset', asset),
            DeviceAlarmSound(:final path) => ('uri', Uri.file(path).toString()),
          };
    return _invoke<void>('preview', {'kind': kind, 'value': value});
  }

  @override
  Future<void> stopPreview() async {
    try {
      await _channel.invokeMethod<void>('stopPreview');
    } on MissingPluginException {
      // 채널이 없으면 재생 중인 것도 없다.
    } on PlatformException {
      // 멈추기는 실패해도 화면을 막지 않는다.
    }
  }

  @override
  Future<AlarmSound> import(DeviceRingtone ringtone) async {
    final path = await _invoke<String>('import', {'uri': ringtone.uri});
    if (path == null || path.isEmpty) {
      throw const AlarmSoundException('import returned no path');
    }
    return AlarmSound.device(title: ringtone.title, path: path);
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw AlarmSoundException('$method: ${e.code} ${e.message}');
    } on MissingPluginException catch (e) {
      throw AlarmSoundException('$method: ${e.message}');
    }
  }
}
