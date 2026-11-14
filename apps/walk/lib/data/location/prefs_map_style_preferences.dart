import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/location/entity/map_style.dart';
import '../../domain/location/repository/map_style_preferences.dart';

/// 값은 enum 이름 문자열로 둔다. 타입이 다르거나 모르는 이름이면 기본값.
@LazySingleton(as: MapStylePreferences)
class PrefsMapStylePreferences implements MapStylePreferences {
  PrefsMapStylePreferences(this._prefs);

  final SharedPreferences _prefs;

  static const styleKey = 'walk.map.style';

  @override
  MapStyle get style => switch (_prefs.get(styleKey)) {
    final String name => MapStyle.values.asNameMap()[name] ?? MapStyle.fallback,
    _ => MapStyle.fallback,
  };

  @override
  Future<void> setStyle(MapStyle value) =>
      _prefs.setString(styleKey, value.name);
}
