import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/activity_period.dart';
import '../format/walk_format.dart';

class PeriodSummary extends StatelessWidget {
  const PeriodSummary({required this.period, super.key});

  final ActivityPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final rows = [
      (
        l10n.walkTotalSteps,
        l10n.walkStepsCount(WalkFormat.steps(locale, period.totalSteps)),
      ),
      (
        l10n.walkAverageSteps,
        l10n.walkStepsCount(WalkFormat.steps(locale, period.averageSteps)),
      ),
      (
        l10n.walkDistance,
        WalkFormat.distance(locale, period.totalDistanceMeters),
      ),
      (
        l10n.walkActiveCalories,
        WalkFormat.kcal(locale, period.totalActiveKcal),
      ),
    ];

    return Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                Text(value, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
      ],
    );
  }
}
