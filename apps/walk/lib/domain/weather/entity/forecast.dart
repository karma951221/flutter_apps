import 'package:freezed_annotation/freezed_annotation.dart';

import 'weather_condition.dart';

part 'forecast.freezed.dart';

/// 한 지역의 예보. 모든 시각은 UTC 절대 시각이다.
/// 지역의 벽시계 시각이 필요하면 [wallClock] 을 쓴다.
@freezed
class Forecast with _$Forecast {
  /// 예보 지역의 UTC 대비 오프셋(기기 시간대가 아니다).
  @override
  final Duration utcOffset;

  @override
  final CurrentWeather current;

  @override
  final List<HourlyWeather> hourly;

  @override
  final List<DailyWeather> daily;

  const Forecast({
    required this.utcOffset,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  /// [instant] 의 필드(년·월·일·시…)가 예보 지역 벽시계인 UTC DateTime.
  DateTime wallClock(DateTime instant) => instant.toUtc().add(utcOffset);
}

/// 지금 날씨.
@freezed
class CurrentWeather with _$CurrentWeather {
  @override
  final DateTime time;

  @override
  final double temperature;

  @override
  final double apparentTemperature;

  @override
  final WeatherCondition condition;

  @override
  final bool isDay;

  /// 상대 습도(%).
  @override
  final int humidity;

  /// 풍속(m/s).
  @override
  final double windSpeed;

  /// 강수량(mm).
  @override
  final double precipitation;

  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.condition,
    required this.isDay,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
  });
}

/// 한 시간 단위 예보.
@freezed
class HourlyWeather with _$HourlyWeather {
  @override
  final DateTime time;

  @override
  final double temperature;

  /// 강수 확률(%). 모델이 주지 않으면 null.
  @override
  final int? precipitationProbability;

  /// 강수량(mm).
  @override
  final double precipitation;

  @override
  final WeatherCondition condition;

  @override
  final bool isDay;

  const HourlyWeather({
    required this.time,
    required this.temperature,
    this.precipitationProbability,
    required this.precipitation,
    required this.condition,
    required this.isDay,
  });
}

/// 하루 단위 예보.
@freezed
class DailyWeather with _$DailyWeather {
  /// 예보 지역 자정의 UTC 시각.
  @override
  final DateTime date;

  @override
  final WeatherCondition condition;

  @override
  final double tempMax;

  @override
  final double tempMin;

  @override
  final int? precipitationProbabilityMax;

  /// 하루 강수량 합(mm).
  @override
  final double precipitationSum;

  @override
  final DateTime? sunrise;

  @override
  final DateTime? sunset;

  const DailyWeather({
    required this.date,
    required this.condition,
    required this.tempMax,
    required this.tempMin,
    this.precipitationProbabilityMax,
    required this.precipitationSum,
    this.sunrise,
    this.sunset,
  });
}
