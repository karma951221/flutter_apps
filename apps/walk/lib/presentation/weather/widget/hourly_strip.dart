import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../../../domain/weather/rain_summary.dart';
import '../format/weather_format.dart';

/// 시간별 — 지금 시간부터 24칸 가로 스크롤.
class HourlyStrip extends StatelessWidget {
  const HourlyStrip({required this.forecast, required this.now, super.key});

  static const hours = 24;

  final Forecast forecast;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 지금이 속한 시간(예보 지역 벽시계)부터.
    final wall = forecast.wallClock(now);
    final hourStart = DateTime.utc(wall.year, wall.month, wall.day, wall.hour);
    final upcoming = [
      for (final h in forecast.hourly)
        if (!forecast.wallClock(h.time).isBefore(hourStart)) h,
    ]..sort((a, b) => a.time.compareTo(b.time));
    final shown = upcoming.take(hours).toList();
    // 칸이 24개뿐이라 한 번에 그린다 — 지연 생성할 만큼 많지 않다.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++)
            HourlyCell(
              hour: shown[i],
              label: i == 0
                  ? l10n.walkWeatherNow
                  : WeatherFormat.hour(l10n, forecast, shown[i].time),
            ),
        ],
      ),
    );
  }
}

/// 시간별 한 칸 — 시각 · 아이콘 · 기온 · 강수확률(비 시간이면 강조색).
class HourlyCell extends StatelessWidget {
  const HourlyCell({required this.hour, required this.label, super.key});

  final HourlyWeather hour;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rainy = isRainyHour(hour);
    return SizedBox(
      width: AppSpacing.xl * 2,
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
          const SizedBox(height: AppSpacing.xs),
          Icon(
            WeatherFormat.icon(hour.condition, isDay: hour.isDay),
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            WeatherFormat.temperature(hour.temperature),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            WeatherFormat.probability(hour.precipitationProbability),
            style: theme.textTheme.bodySmall?.copyWith(
              color: rainy ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: rainy ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
