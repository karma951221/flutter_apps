import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/alarm/entity/ring_log_entry.dart';
import '../../domain/alarm/ring_log/ring_log_source.dart';

/// `RingLogChannel.kt`(`walk/ring_log`)로 포크 네이티브의 울림 기록(`RingLog`)을 읽고 덧붙인다.
///
/// 채널 약속:
/// - `read` → `[String]`: 한 줄에 JSON 하나 `{"at": epoch millis, "packageId": int, "kind": 이름}`,
///   오래된 것부터(최근 200개).
/// - `append` ← `{at: epoch millis, packageId: int, kind: 이름}`
///
/// 채널이 없으면(테스트 · 네이티브 미연결) 빈 목록 · 무시. 네이티브 오류는 던진다.
@LazySingleton(as: RingLogSource)
class ChannelRingLogSource implements RingLogSource {
  const ChannelRingLogSource();

  static const channelName = 'walk/ring_log';
  static const _channel = MethodChannel(channelName);

  @override
  Future<List<RingLogEntry>> read({required DateTime since}) async {
    final List<Object?>? lines;
    try {
      lines = await _channel.invokeMethod<List<Object?>>('read');
    } on MissingPluginException {
      return const [];
    }
    final entries = [
      for (final line in lines ?? const [])
        if (line is String) ?_decode(line),
    ];
    return [
      for (final entry in entries)
        if (!entry.at.isBefore(since)) entry,
    ];
  }

  @override
  Future<void> append(RingLogEntry entry) async {
    try {
      await _channel.invokeMethod<void>('append', {
        'at': entry.at.millisecondsSinceEpoch,
        'packageId': entry.packageId,
        'kind': entry.kind.name,
      });
    } on MissingPluginException {
      // 네이티브가 없으면 기록 없이 지낸다.
    }
  }

  static RingLogEntry? _decode(String line) {
    final Object? json;
    try {
      json = jsonDecode(line);
    } on FormatException {
      return null;
    }
    if (json case {
      'at': final int at,
      'packageId': final int packageId,
      'kind': final String kind,
    }) {
      final known = RingLogKind.values.where((k) => k.name == kind).firstOrNull;
      if (known == null) return null;
      return RingLogEntry(
        at: DateTime.fromMillisecondsSinceEpoch(at),
        packageId: packageId,
        kind: known,
      );
    }
    return null;
  }
}
