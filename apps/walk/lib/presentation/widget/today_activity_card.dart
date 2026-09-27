import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/daily_activity.dart';
import '../format/walk_format.dart';

class TodayActivityCard extends StatelessWidget {
  const TodayActivityCard({required this.activity, super.key});

  final DailyActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(l10n.walkToday, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.walkStepsCount(WalkFormat.steps(locale, activity.steps)),
              key: const Key('walk-today-steps'),
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Metric(
                  label: l10n.walkDistance,
                  value: WalkFormat.distance(locale, activity.distanceMeters),
                ),
                _Metric(
                  label: l10n.walkActiveCalories,
                  value: WalkFormat.kcal(locale, activity.activeKcal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
