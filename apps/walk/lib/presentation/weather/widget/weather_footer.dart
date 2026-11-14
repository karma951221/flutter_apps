import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../format/weather_format.dart';

/// 꼬리 — 마지막으로 **성공**한 시각과 출처("14:02 갱신 · Open-Meteo").
class WeatherFooter extends StatelessWidget {
  const WeatherFooter({
    required this.forecast,
    required this.fetchedAt,
    super.key,
  });

  final Forecast forecast;
  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Text(
      l10n.walkWeatherUpdated(WeatherFormat.clock(forecast, fetchedAt)),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
