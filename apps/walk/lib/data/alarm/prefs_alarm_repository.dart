import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/alarm/entity/alarm.dart';
import '../../domain/alarm/repository/alarm_repository.dart';

/// 알람 정의를 JSON 배열 하나로 저장한다. 수십 개 수준이라 DB 가 필요 없다.
@LazySingleton(as: AlarmRepository)
class PrefsAlarmRepository implements AlarmRepository {
  PrefsAlarmRepository(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'walk.alarms';

  /// 읽다 깨진 걸 발견하면 원본을 여기 남긴다. 다음 깨짐이 덮어쓴다.
  static const corruptKey = 'walk.alarms.corrupt';

  /// 절대 던지지 않는다 — 깨진 항목만 건너뛰고, 전체가 깨졌으면 빈 목록.
  @override
  Future<List<Alarm>> load() async {
    final raw = _prefs.get(key);
    if (raw == null) return [];
    if (raw is! String) {
      await _backup(raw.toString());
      return [];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      await _backup(raw);
      return [];
    }
    if (decoded is! List<Object?>) {
      await _backup(raw);
      return [];
    }

    final alarms = <Alarm>[];
    var corrupt = false;
    for (final item in decoded) {
      try {
        alarms.add(Alarm.fromJson(item! as Map<String, Object?>));
      } on Object {
        corrupt = true;
      }
    }
    if (corrupt) await _backup(raw);
    return alarms;
  }

  Future<void> _backup(String raw) => _prefs.setString(corruptKey, raw);

  @override
  Future<void> save(List<Alarm> alarms) async {
    await _prefs.setString(key, jsonEncode([for (final a in alarms) a.toJson()]));
  }
}
