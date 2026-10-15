import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/period_summary.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';

/// 피드 타임라인 위의 '이번 주' 한 줄. 누를 수 있는 것이라 남색 글자에 화살표.
class WeekSummaryLine extends StatelessWidget {
  const WeekSummaryLine({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final PeriodSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final theme = Theme.of(context);
    final text = summary.walkCount == 0
        ? l10n.walkFeedWeekSummaryEmpty
        : l10n.walkFeedWeekSummary(
            WalkFormat.distance(l10n, summary.distanceMeters),
            summary.walkCount,
          );

    return InkWell(
      key: const Key('walk-feed-week-summary'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PawlogSize.gutter,
          vertical: PawlogSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
