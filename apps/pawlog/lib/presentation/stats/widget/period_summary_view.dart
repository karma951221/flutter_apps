import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/period_stats.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';
import '../format/stats_format.dart';

/// 기간 요약 — 거리 히어로 숫자 하나 + 시간 · 횟수, 그리고 지난 기간 비교 한 줄.
class PeriodSummaryView extends StatelessWidget {
  const PeriodSummaryView({required this.stats, super.key});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final styles = PawlogTextStyles.of(context);
    final theme = Theme.of(context);
    final summary = stats.summary;
    final comparison = StatsFormat.comparison(l10n, stats);
    final label = theme.textTheme.labelMedium?.copyWith(
      color: colors.textMuted,
    );
    // 0건 기간의 시간은 '1분 미만' 이 아니라 0분이다.
    final duration = summary.walkCount == 0
        ? l10n.walkDurationMinutes(0)
        : WalkFormat.duration(l10n, summary.duration);

    Widget figure(String name, String value, Key key) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: label),
        Text(value, key: key, style: styles.number),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.walkStatsDistanceLabel, style: label),
        Text(
          WalkFormat.distance(l10n, summary.distanceMeters),
          key: const Key('stats-total-distance'),
          style: styles.numberHero,
        ),
        if (comparison != null) ...[
          const SizedBox(height: PawlogSpacing.xs),
          Text(
            comparison,
            key: const Key('stats-comparison'),
            style: theme.textTheme.bodyLarge?.copyWith(color: colors.textMuted),
          ),
        ],
        const SizedBox(height: PawlogSpacing.lg),
        Row(
          children: [
            Expanded(
              child: figure(
                l10n.walkStatsDurationLabel,
                duration,
                const Key('stats-total-duration'),
              ),
            ),
            Expanded(
              child: figure(
                l10n.walkStatsCountLabel,
                l10n.walkStatsCountValue(summary.walkCount),
                const Key('stats-total-count'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
