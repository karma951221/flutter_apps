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
  ///
  /// 읽기 전에 디스크에서 다시 읽는다. `SharedPreferences` 는 isolate 마다 메모리 사본을 한 번만
  /// 읽는데, 헤드리스 엔진(미리 알림의 [이번만 끄기] · 하루 sync)이 다른 isolate 에서 알람을 바꾼다.
  /// 메인 엔진이 옛 사본으로 sync 하면 건너뛴 회차를 다시 걸고, 저장하면 그 변경을 덮어쓴다.
  @override
  Future<List<Alarm>> load() async {
    try {
      await _prefs.reload();
    } on Object {
      // 다시 읽지 못하면 가진 사본으로 읽는다.
    }
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
    await _prefs.setString(
      key,
      jsonEncode([for (final a in alarms) a.toJson()]),
    );
  }
}
