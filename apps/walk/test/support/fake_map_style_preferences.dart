import 'package:walk/domain/location/entity/map_style.dart';
import 'package:walk/domain/location/repository/map_style_preferences.dart';

/// 메모리에만 두는 지도 모양 설정.
class FakeMapStylePreferences implements MapStylePreferences {
  FakeMapStylePreferences([this.style = MapStyle.fallback]);

  @override
  MapStyle style;

  @override
  Future<void> setStyle(MapStyle value) async => style = value;
}
