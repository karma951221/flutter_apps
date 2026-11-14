import 'package:freezed_annotation/freezed_annotation.dart';

import '../entity/forecast.dart';

part 'weather_repository.freezed.dart';

/// 가져온 예보와 그 원본. [payload] 는 출처가 정하는 불투명 문자열이다.
@freezed
class FetchedForecast with _$FetchedForecast {
  @override
  final Forecast forecast;

  @override
  final String payload;

  const FetchedForecast({required this.forecast, required this.payload});
}

/// 좌표의 날씨 예보를 가져온다. 실패는 `WeatherFailure` 로 던진다.
abstract interface class WeatherRepository {
  Future<FetchedForecast> fetch(double lat, double lng);

  /// 캐시에 저장해 둔 [payload] 를 예보로 되살린다. 해석 못 하면 `WeatherFailure(server)`.
  Forecast decode(String payload);
}
