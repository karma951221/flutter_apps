import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../format/weather_format.dart';

/// 일별 — 7일, 날마다 최저–최고 막대. 막대는 주 전체 기온 범위 위에 놓는다.
class DailyList extends StatelessWidget {
  const DailyList({required this.forecast, required this.now, super.key});

  static const days = 7;

  final Forecast forecast;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = forecast.daily.take(days).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final low = shown.map((d) => d.tempMin).reduce(math.min);
    final high = shown.map((d) => d.tempMax).reduce(math.max);
    return Column(
      children: [
        for (final day in shown)
          DailyRow(
            day: day,
            label: WeatherFormat.day(l10n, forecast, day.date, now),
            weekLow: low,
            weekHigh: high,
          ),
      ],
    );
  }
}

/// 일별 한 행 — 날 · 아이콘 · 최대 강수확률 · 최저 ━━ 최고.
///
/// `AppListTile` 의 leading/title/trailing 세 칸으로는 막대를 가운데 두고 양옆 기온을
/// 열 맞춰 세울 수 없어 행을 직접 짠다. 여백 · 색은 토큰만 쓴다.
class DailyRow extends StatelessWidget {
  const DailyRow({
    required this.day,
    required this.label,
    required this.weekLow,
    required this.weekHigh,
    super.key,
  });

  final DailyWeather day;
  final String label;
  final double weekLow;
  final double weekHigh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final probability = day.precipitationProbabilityMax;
    final rainy = (probability ?? 0) >= 50;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.xl * 2,
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          Icon(
            WeatherFormat.icon(day.condition, isDay: true),
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(
            width: AppSpacing.xl * 1.5,
            child: Text(
              WeatherFormat.probability(probability),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: rainy ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: AppSpacing.xl * 1.5,
            child: Text(
              WeatherFormat.temperature(day.tempMin),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _RangeBar(
              low: day.tempMin,
              high: day.tempMax,
              weekLow: weekLow,
              weekHigh: weekHigh,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: AppSpacing.xl,
            child: Text(
              WeatherFormat.temperature(day.tempMax),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// 주 전체 범위([weekLow]–[weekHigh]) 위의 그날 최저–최고 막대.
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.low,
    required this.high,
    required this.weekLow,
    required this.weekHigh,
  });

  final double low;
  final double high;
  final double weekLow;
  final double weekHigh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final span = weekHigh - weekLow;
    // 주 내내 기온이 같으면 막대를 가득 채운다.
    final start = span <= 0 ? 0.0 : ((low - weekLow) / span).clamp(0.0, 1.0);
    final end = span <= 0 ? 1.0 : ((high - weekLow) / span).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: AppSpacing.xs,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: AppRadius.smAll,
                  ),
                ),
              ),
              Positioned(
                left: width * start,
                width: math.max(width * (end - start), AppSpacing.xs),
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: AppRadius.smAll,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
