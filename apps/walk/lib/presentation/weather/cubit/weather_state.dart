import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../../../domain/weather/weather_problem.dart';

part 'weather_state.freezed.dart';

@freezed
sealed class WeatherState with _$WeatherState {
  /// 보여 줄 예보도, 쓸 수 있는 캐시도 아직 없다.
  const factory WeatherState.loading() = WeatherLoading;

  /// 예보를 보이는 중. [fetchedAt] 은 이 예보를 **성공적으로** 받은 시각이다.
  ///
  /// [refreshing] — 뒤에서 다시 읽는 중. [stale] — 이번 요청이 실패해 캐시 예보를 보이는 중.
  /// [problem] — 이번 갱신에서 생긴 문제. 위치 실패 뒤 캐시 좌표로 새 예보를 받았으면
  /// `stale: false` 이고 [problem] 은 위치 문제다. [placeName] 이 null 이면 "현재 위치".
  const factory WeatherState.loaded({
    required Forecast forecast,
    String? placeName,
    required DateTime fetchedAt,
    @Default(false) bool refreshing,
    @Default(false) bool stale,
    WeatherProblem? problem,
  }) = WeatherLoaded;

  /// 쓸 수 있는 캐시도 없이 실패했다.
  const factory WeatherState.empty(WeatherProblem problem) = WeatherEmpty;
}
