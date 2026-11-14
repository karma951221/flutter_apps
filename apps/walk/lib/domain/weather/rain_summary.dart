import 'package:freezed_annotation/freezed_annotation.dart';

import 'entity/forecast.dart';
import 'entity/weather_condition.dart';

part 'rain_summary.freezed.dart';

/// 앞으로의 비 요약. 시각은 UTC 절대 시각이다.
@freezed
sealed class RainSummary with _$RainSummary {
  /// 지금 비가 온다. 창 안에서 그치면 [stopsAt], 아니면 null.
  const factory RainSummary.now({
    DateTime? stopsAt,
    required bool snow,
    required int maxProbability,
    required double totalMm,
  }) = RainNow;

  /// 지금은 아니지만 창 안에서 비가 시작한다.
  const factory RainSummary.later({
    required DateTime startsAt,
    required bool snow,
    required int maxProbability,
    required double totalMm,
  }) = RainLater;

  /// 창 안에 비가 없다. [maxProbability] 는 창 전체의 최대 확률.
  const factory RainSummary.none({required int maxProbability}) = NoRain;
}

const _rainProbability = 50;
const _rainMm = 0.1;
const _shortDay = Duration(hours: 6);
const _longWindow = Duration(hours: 12);

/// "비 시간" — 강수확률 50% 이상이거나 강수량 0.1mm 이상. 화면의 시간별 강조도 이 규칙을 쓴다.
bool isRainyHour(HourlyWeather h) =>
    (h.precipitationProbability ?? 0) >= _rainProbability ||
    h.precipitation >= _rainMm;

/// [now] 가 속한 시간부터 예보 지역의 다음 자정 전까지(자정까지 6시간
/// 미만이면 12시간)를 훑어 비 요약을 만든다. 날짜 경계는 기기가 아니라
/// 예보 지역 기준이다.
RainSummary summarizeRain(Forecast forecast, DateTime now) {
  final wall = forecast.wallClock(now);
  final hourStart = DateTime.utc(wall.year, wall.month, wall.day, wall.hour);
  final midnight = DateTime.utc(wall.year, wall.month, wall.day + 1);
  final end = midnight.difference(wall) < _shortDay
      ? hourStart.add(_longWindow)
      : midnight;

  final window = [
    for (final h in forecast.hourly)
      if (!forecast.wallClock(h.time).isBefore(hourStart) &&
          forecast.wallClock(h.time).isBefore(end))
        h,
  ]..sort((a, b) => a.time.compareTo(b.time));

  final rainy = window.where(isRainyHour).toList();
  int maxOf(Iterable<HourlyWeather> hours) => hours.fold(
    0,
    (m, h) =>
        (h.precipitationProbability ?? 0) > m ? h.precipitationProbability! : m,
  );
  if (rainy.isEmpty) return RainSummary.none(maxProbability: maxOf(window));

  final first = rainy.first;
  final snow = first.condition == WeatherCondition.snow;
  final maxProbability = maxOf(rainy);
  final totalMm = rainy.fold<double>(0, (s, h) => s + h.precipitation);

  final isNow = !forecast.wallClock(first.time).isAfter(hourStart);
  if (!isNow) {
    return RainSummary.later(
      startsAt: first.time,
      snow: snow,
      maxProbability: maxProbability,
      totalMm: totalMm,
    );
  }
  DateTime? stopsAt;
  for (final h in window) {
    if (h.time.isAfter(first.time) && !isRainyHour(h)) {
      stopsAt = h.time;
      break;
    }
  }
  return RainSummary.now(
    stopsAt: stopsAt,
    snow: snow,
    maxProbability: maxProbability,
    totalMm: totalMm,
  );
}
