import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_cache.freezed.dart';

/// 마지막으로 받은 예보. 오프라인일 때 보여 준다.
///
/// [payload] 는 예보 원문(JSON 문자열)이라 저장소는 내용을 해석하지 않는다.
@freezed
class CachedForecast with _$CachedForecast {
  @override
  final String payload;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final String? placeName;
  @override
  final DateTime fetchedAt;

  const CachedForecast({
    required this.payload,
    required this.lat,
    required this.lng,
    this.placeName,
    required this.fetchedAt,
  });
}

abstract interface class WeatherCache {
  /// 없거나 읽을 수 없으면 null. 던지지 않는다.
  Future<CachedForecast?> read();

  Future<void> write(CachedForecast value);
}
