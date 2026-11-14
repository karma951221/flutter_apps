import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../format/weather_format.dart';

/// 세부 한 줄 — 습도 · 바람 · 일출 · 일몰. 일출 · 일몰을 모르면 뺀다.
class WeatherDetailsRow extends StatelessWidget {
  const WeatherDetailsRow({
    required this.forecast,
    required this.today,
    super.key,
  });

  final Forecast forecast;
  final DailyWeather? today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = forecast.current;
    final sunrise = today?.sunrise;
    final sunset = today?.sunset;
    final items = [
      l10n.walkWeatherHumidity(current.humidity),
      l10n.walkWeatherWind(
        WeatherFormat.windSpeed(l10n.localeName, current.windSpeed),
      ),
      if (sunrise != null)
        l10n.walkWeatherSunrise(WeatherFormat.clock(forecast, sunrise)),
      if (sunset != null)
        l10n.walkWeatherSunset(WeatherFormat.clock(forecast, sunset)),
    ];
    return Text(
      items.join(' · '),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
