import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../format/weather_format.dart';

/// 지금 날씨 — 장소 · 큰 기온 · 하늘 상태 · 체감 · 오늘 최고/최저.
class WeatherNowHeader extends StatelessWidget {
  const WeatherNowHeader({
    required this.current,
    required this.today,
    required this.placeName,
    this.lastPlace = false,
    super.key,
  });

  final CurrentWeather current;

  /// 예보 지역의 오늘. 일별이 비어 있으면 null — 최고/최저를 빼고 그린다.
  final DailyWeather? today;

  /// null 이면 "현재 위치"([lastPlace] 면 "마지막 위치").
  final String? placeName;

  /// 위치를 못 잡아 마지막 위치의 예보를 보이는 중. 이름이 없을 때 문구를 바꾼다.
  final bool lastPlace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = today;
    final feels = l10n.walkWeatherFeelsLike(
      WeatherFormat.temperature(current.apparentTemperature),
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                placeName ??
                    (lastPlace
                        ? l10n.walkWeatherLastPlace
                        : l10n.walkWeatherCurrentPlace),
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // 큰 글자 설정에서 좁은 폭을 넘으면 줄여서 맞춘다.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                WeatherFormat.temperature(current.temperature),
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                children: [
                  Icon(
                    WeatherFormat.icon(current.condition, isDay: current.isDay),
                    size: AppSpacing.xl,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    WeatherFormat.condition(l10n, current.condition),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          day == null
              ? feels
              : '$feels · ${l10n.walkWeatherHighLow(WeatherFormat.temperature(day.tempMax), WeatherFormat.temperature(day.tempMin))}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
