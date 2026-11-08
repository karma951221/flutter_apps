import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/location/entity/record_retention.dart';
import '../../domain/location/repository/location_preferences.dart';

/// 값은 enum 이름 문자열로 둔다. 타입이 다르거나 모르는 이름이면 기본값.
@LazySingleton(as: LocationPreferences)
class PrefsLocationPreferences implements LocationPreferences {
  PrefsLocationPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const retentionKey = 'walk.location.retention';

  // getString 은 문자열이 아닌 값에서 던지므로 get 으로 읽고 타입을 확인한다.
  String? _string(String key) => switch (_prefs.get(key)) {
    final String value => value,
    _ => null,
  };

  @override
  RecordRetention get retention =>
      RecordRetention.values.asNameMap()[_string(retentionKey)] ??
      RecordRetention.fallback;

  @override
  Future<void> setRetention(RecordRetention value) =>
      _prefs.setString(retentionKey, value.name);
}
