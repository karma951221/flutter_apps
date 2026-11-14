import '../entity/map_style.dart';

/// 지도 모양 설정. 읽기는 동기, 저장된 값이 깨졌으면 기본값([MapStyle.fallback]).
abstract interface class MapStylePreferences {
  MapStyle get style;
  Future<void> setStyle(MapStyle value);
}
