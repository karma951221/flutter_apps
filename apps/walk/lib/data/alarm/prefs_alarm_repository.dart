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

  @override
  Future<List<Alarm>> load() async {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<Object?>;
    return [for (final item in list) Alarm.fromJson(item! as Map<String, Object?>)];
  }

  @override
  Future<void> save(List<Alarm> alarms) async {
    await _prefs.setString(key, jsonEncode([for (final a in alarms) a.toJson()]));
  }
}
