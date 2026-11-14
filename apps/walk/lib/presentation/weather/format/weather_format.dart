import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../../../domain/weather/entity/weather_condition.dart';
import '../../../domain/weather/rain_summary.dart';
import '../../../domain/weather/weather_problem.dart';

/// 날씨 화면의 아이콘 · 문구 · 시각 표기를 한곳에 둔다.
///
/// 시각은 모두 예보 지역의 벽시계([Forecast.wallClock])로 적는다 — 기기 시간대
/// (`toLocal`)를 쓰면 여행 중이거나 오래된 캐시에서 "오후 3시"가 어긋난다.
abstract final class WeatherFormat {
  /// 상태 → Material 아이콘. 밤에는 맑음 · 구름 조금만 달 아이콘으로 바꾼다.
  static IconData icon(WeatherCondition condition, {required bool isDay}) =>
      switch (condition) {
        WeatherCondition.clear =>
          isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round,
        WeatherCondition.partlyCloudy =>
          isDay ? Icons.wb_cloudy_outlined : Icons.nights_stay,
        WeatherCondition.cloudy => Icons.cloud_outlined,
        WeatherCondition.fog => Icons.foggy,
        WeatherCondition.drizzle => Icons.grain,
        WeatherCondition.rain => Icons.umbrella_outlined,
        WeatherCondition.showers => Icons.water_drop_outlined,
        WeatherCondition.snow => Icons.ac_unit,
        WeatherCondition.thunderstorm => Icons.thunderstorm_outlined,
        WeatherCondition.unknown => Icons.help_outline,
      };

  /// 상태의 짧은 이름.
  static String condition(AppLocalizations l10n, WeatherCondition condition) =>
      switch (condition) {
        WeatherCondition.clear => l10n.walkWeatherConditionClear,
        WeatherCondition.partlyCloudy => l10n.walkWeatherConditionPartlyCloudy,
        WeatherCondition.cloudy => l10n.walkWeatherConditionCloudy,
        WeatherCondition.fog => l10n.walkWeatherConditionFog,
        WeatherCondition.drizzle => l10n.walkWeatherConditionDrizzle,
        WeatherCondition.rain => l10n.walkWeatherConditionRain,
        WeatherCondition.showers => l10n.walkWeatherConditionShowers,
        WeatherCondition.snow => l10n.walkWeatherConditionSnow,
        WeatherCondition.thunderstorm => l10n.walkWeatherConditionThunderstorm,
        WeatherCondition.unknown => l10n.walkWeatherConditionUnknown,
      };

  /// 정수로 반올림한 기온("12°").
  static String temperature(double celsius) => '${celsius.round()}°';

  /// 강수확률("70%"). 모델이 주지 않았으면 "–".
  static String probability(int? percent) =>
      percent == null ? '–' : '$percent%';

  /// 강수량. 10mm 미만은 소수 한 자리까지, 그 이상은 정수("0.4" · "1.7" · "12").
  static String amount(String locale, double mm) =>
      NumberFormat(mm < 10 ? '0.#' : '0', locale).format(mm);

  /// 풍속(m/s) — 소수 한 자리까지.
  static String windSpeed(String locale, double speed) =>
      NumberFormat('0.#', locale).format(speed);

  /// 예보 지역의 시("오후 3시"). 날짜는 붙이지 않는다.
  static String hour(
    AppLocalizations l10n,
    Forecast forecast,
    DateTime instant,
  ) => DateFormat.j(l10n.localeName).format(forecast.wallClock(instant));

  /// 예보 지역의 "HH:mm"(일출 · 일몰 · 갱신 시각).
  static String clock(Forecast forecast, DateTime instant) =>
      DateFormat('HH:mm').format(forecast.wallClock(instant));

  /// [now] 와 같은 날이면 "오후 3시", 다음 날이면 "내일 오전 5시". 날짜 경계는 예보 지역 기준.
  static String time(
    AppLocalizations l10n,
    Forecast forecast,
    DateTime instant,
    DateTime now,
  ) {
    final label = hour(l10n, forecast, instant);
    return switch (_daysBetween(forecast, now, instant)) {
      0 => label,
      1 => l10n.walkWeatherTomorrowTime(label),
      _ =>
        '${DateFormat.MMMEd(l10n.localeName).format(forecast.wallClock(instant))} $label',
    };
  }

  /// 일별 행의 날 이름 — "오늘" · "내일" · 그 뒤는 요일.
  static String day(
    AppLocalizations l10n,
    Forecast forecast,
    DateTime date,
    DateTime now,
  ) => switch (_daysBetween(forecast, now, date)) {
    0 => l10n.walkWeatherToday,
    1 => l10n.walkWeatherTomorrow,
    _ => DateFormat.E(l10n.localeName).format(forecast.wallClock(date)),
  };

  /// [from] 에서 [to] 까지 예보 지역 달력으로 며칠 뒤인지.
  static int _daysBetween(Forecast forecast, DateTime from, DateTime to) {
    final a = forecast.wallClock(from);
    final b = forecast.wallClock(to);
    return DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  }

  /// 비 요약 카드의 제목 · 부제.
  static ({String title, String subtitle}) rain(
    AppLocalizations l10n,
    Forecast forecast,
    RainSummary summary,
    DateTime now,
  ) {
    String at(DateTime instant) => time(l10n, forecast, instant, now);
    String detail(int probability, double totalMm) {
      final mm = amount(l10n.localeName, totalMm);
      // 반올림해 0 이면 "0mm" 대신 확률만 적는다.
      return mm == '0'
          ? l10n.walkWeatherRainChance(probability)
          : l10n.walkWeatherRainAmount(probability, mm);
    }

    return switch (summary) {
      RainNow(
        :final stopsAt?,
        :final snow,
        :final maxProbability,
        :final totalMm,
      ) =>
        (
          title: snow
              ? l10n.walkWeatherSnowNowStops(at(stopsAt))
              : l10n.walkWeatherRainNowStops(at(stopsAt)),
          subtitle: detail(maxProbability, totalMm),
        ),
      RainNow(:final snow, :final maxProbability, :final totalMm) => (
        title: snow ? l10n.walkWeatherSnowNowLate : l10n.walkWeatherRainNowLate,
        subtitle: detail(maxProbability, totalMm),
      ),
      RainLater(
        :final startsAt,
        :final snow,
        :final maxProbability,
        :final totalMm,
      ) =>
        (
          title: snow
              ? l10n.walkWeatherSnowLater(at(startsAt))
              : l10n.walkWeatherRainLater(at(startsAt)),
          subtitle: detail(maxProbability, totalMm),
        ),
      NoRain(:final maxProbability) => (
        title: l10n.walkWeatherNoRain,
        subtitle: l10n.walkWeatherRainChance(maxProbability),
      ),
    };
  }

  /// 예보 위 한 줄 — 왜 이 예보를 보이는지.
  ///
  /// [stale] 이면 이번 요청이 실패해 [fetchedAt] 에 받은 캐시를 보이는 중이고,
  /// 아니면 위치만 실패해 마지막 위치로 새 예보를 받은 것이다.
  static String problem(
    AppLocalizations l10n,
    WeatherProblem problem, {
    required bool stale,
    required String? placeName,
    required DateTime fetchedAt,
    required DateTime now,
  }) {
    final reason = switch (problem) {
      WeatherProblem.locationServiceOff => l10n.walkWeatherReasonLocationOff,
      WeatherProblem.locationDenied => l10n.walkWeatherReasonLocationDenied,
      WeatherProblem.locationUnavailable =>
        l10n.walkWeatherReasonLocationUnavailable,
      WeatherProblem.offline => l10n.walkWeatherReasonOffline,
      WeatherProblem.server => l10n.walkWeatherReasonServer,
    };
    if (!stale) {
      return placeName == null
          ? l10n.walkWeatherProblemLastPlaceUnnamed(reason)
          : l10n.walkWeatherProblemLastPlace(reason, placeName);
    }
    final elapsed = now.difference(fetchedAt);
    final age = elapsed.inHours >= 1
        ? l10n.walkWeatherHoursAgo(elapsed.inHours)
        : l10n.walkWeatherMinutesAgo(elapsed.inMinutes.clamp(1, 59));
    return l10n.walkWeatherProblemStale(
      reason,
      age,
      placeName ?? l10n.walkWeatherLastPlace,
    );
  }
}
