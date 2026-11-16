import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_failure.dart';
import 'area_io.dart';

/// 허용 목록 prefs 를 `{key: {type, value}}` 로 옮긴다. JSON 은 3 과 3.0 을 가리지 못하므로
/// 타입을 함께 적는다. 타입: `bool` · `int` · `double` · `string` · `stringList`.
///
/// 목록 밖의 키(API 키 · 잠금 · 캐시 · 동의)는 읽지도 쓰지도 않는다.
Future<Map<String, Object?>> dumpPrefs(
  SharedPreferences prefs,
  Set<String> keys,
) async => {
  for (final key in keys)
    if (_encode(prefs.get(key)) case final Object entry) key: entry,
};

/// [json] 으로 허용 목록 prefs 를 바꾼다 — 목록 키를 먼저 지우고 백업에 있는 것만 쓴다.
/// 목록 밖의 키는 무시한다. 항목 하나라도 모양이 다르면 아무것도 바꾸기 전에 integrity.
Future<void> restorePrefs(
  SharedPreferences prefs,
  Set<String> keys,
  Map<String, Object?> json,
) async {
  final values = _decodeAll(keys, json);
  for (final key in keys) {
    await prefs.remove(key);
  }
  for (final MapEntry(:key, :value) in values.entries) {
    await switch (value) {
      final bool v => prefs.setBool(key, v),
      final int v => prefs.setInt(key, v),
      final double v => prefs.setDouble(key, v),
      final String v => prefs.setString(key, v),
      final List<String> v => prefs.setStringList(key, v),
      _ => throw StateError('unreachable: $value'),
    };
  }
}

/// `dir/name` 을 읽어 모양을 확인한 스냅샷. 파일이 없으면 빈 스냅샷.
/// DB 를 바꾸기 전에 불러 두면 커밋 뒤의 [restorePrefs] 가 integrity 로 실패하지 않는다.
Future<Map<String, Object?>> readPrefsSnapshot(
  Directory dir,
  String name,
  Set<String> keys,
) async {
  final json = await readAreaJson(dir, name, optional: true);
  _decodeAll(keys, json);
  return json;
}

Map<String, Object?>? _encode(Object? value) => switch (value) {
  final bool v => {'type': 'bool', 'value': v},
  final int v => {'type': 'int', 'value': v},
  final double v => {'type': 'double', 'value': v},
  final String v => {'type': 'string', 'value': v},
  final List<Object?> v => {'type': 'stringList', 'value': v},
  _ => null,
};

Map<String, Object> _decodeAll(Set<String> keys, Map<String, Object?> json) => {
  for (final key in keys)
    if (json.containsKey(key)) key: _decode(json[key]),
};

Object _decode(Object? entry) => switch (entry) {
  {'type': 'bool', 'value': final bool v} => v,
  {'type': 'int', 'value': final int v} => v,
  {'type': 'double', 'value': final num v} => v.toDouble(),
  {'type': 'string', 'value': final String v} => v,
  {'type': 'stringList', 'value': final List<Object?> v}
      when v.every((e) => e is String) =>
    v.cast<String>().toList(),
  _ => throw const BackupException(BackupFailure.integrity),
};
