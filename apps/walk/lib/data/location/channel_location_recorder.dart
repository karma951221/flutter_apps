import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/location/entity/location_point.dart';
import '../../domain/location/entity/record_mode.dart';
import '../../domain/location/recorder/location_recorder.dart';
import '../../domain/location/recorder/recorder_status.dart';

/// `LocationRecordChannel.kt`(`com.karma.walk/location_record`)로 위치 기록
/// 서비스를 다룬다.
///
/// 채널 약속:
/// - `start`/`setMode` ← `{mode: "normal"|"dense"}`, `stop` → null
/// - `status` → `{state: "off"|"running"|"blocked", mode, stillDetection: bool}`
/// - `drain` ← `{limit}` → `[{id, t: epoch millis UTC, lat, lng, acc: double?, mode, still}]` (id 오름차순)
/// - `ack` ← `{upToId}`
/// - `clearInbox` → null (inbox 의 점을 모두 지운다)
/// - `openBatterySettings` → null (시스템 배터리 최적화 화면)
@LazySingleton(as: LocationRecorder)
class ChannelLocationRecorder implements LocationRecorder {
  const ChannelLocationRecorder();

  static const channelName = 'com.karma.walk/location_record';
  static const _channel = MethodChannel(channelName);

  @override
  Future<RecorderStatus> status() async {
    final map = await _channel.invokeMapMethod<String, Object?>('status');
    final mode = _mode(map?['mode']);
    return switch (map?['state']) {
      'running' => RecorderStatus.running(
        mode,
        stillDetection: map?['stillDetection'] == true,
      ),
      'blocked' => RecorderStatus.blocked(mode),
      _ => const RecorderStatus.off(),
    };
  }

  @override
  Future<void> start(RecordMode mode) =>
      _channel.invokeMethod<void>('start', {'mode': mode.name});

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  Future<void> setMode(RecordMode mode) =>
      _channel.invokeMethod<void>('setMode', {'mode': mode.name});

  @override
  Future<void> openBatterySettings() =>
      _channel.invokeMethod<void>('openBatterySettings');

  @override
  Future<List<({int id, LocationPoint point})>> drain({
    int limit = 2000,
  }) async {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'drain',
      {'limit': limit},
    );
    return [
      for (final row in rows ?? const <Map<Object?, Object?>>[])
        (
          id: (row['id']! as num).toInt(),
          point: LocationPoint(
            recordedAt: DateTime.fromMillisecondsSinceEpoch(
              (row['t']! as num).toInt(),
              isUtc: true,
            ),
            lat: (row['lat']! as num).toDouble(),
            lng: (row['lng']! as num).toDouble(),
            accuracyM: (row['acc'] as num?)?.toDouble(),
            mode: _mode(row['mode']),
            stillStart: row['still'] == true,
          ),
        ),
    ];
  }

  @override
  Future<void> ack(int upToId) =>
      _channel.invokeMethod<void>('ack', {'upToId': upToId});

  @override
  Future<void> clearInbox() => _channel.invokeMethod<void>('clearInbox');

  static RecordMode _mode(Object? name) =>
      name == 'dense' ? RecordMode.dense : RecordMode.normal;
}
