import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../../../domain/weather/rain_summary.dart';
import '../format/weather_format.dart';

/// 비 요약 한 줄 — "오후 3시쯤부터 비가 와요" + 최대 확률 · 강수량.
class RainSummaryCard extends StatelessWidget {
  const RainSummaryCard({
    required this.forecast,
    required this.summary,
    required this.now,
    super.key,
  });

  final Forecast forecast;
  final RainSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final copy = WeatherFormat.rain(l10n, forecast, summary, now);
    final (icon, color) = switch (summary) {
      RainNow(snow: true) ||
      RainLater(snow: true) => (Icons.ac_unit, scheme.primary),
      RainNow() || RainLater() => (Icons.umbrella_outlined, scheme.primary),
      NoRain() => (Icons.wb_sunny_outlined, scheme.onSurfaceVariant),
    };
    return Card(
      child: AppListTile(
        leading: Icon(icon, color: color),
        title: Text(copy.title),
        subtitle: Text(copy.subtitle),
      ),
    );
  }
}
