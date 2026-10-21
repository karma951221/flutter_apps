import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/activity_period.dart';
import '../format/walk_format.dart';

/// 기간 요약 — 맨 위 `달성 n/m일`(오늘까지 지난 날 기준), 아래 합계 · 일평균 타일.
class PeriodSummary extends StatelessWidget {
  const PeriodSummary({required this.period, required this.goal, super.key});

  final ActivityPeriod period;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final elapsed = period.days.where((day) => !day.date.isAfter(period.today));
    final reached = elapsed.where((day) => day.steps >= goal).length;

    final total = _MetricTile(
      icon: Icons.directions_walk,
      value: l10n.walkStepsCount(WalkFormat.steps(locale, period.totalSteps)),
      label: l10n.walkTotalSteps,
    );
    final average = _MetricTile(
      icon: Icons.calendar_today,
      value: l10n.walkStepsCount(WalkFormat.steps(locale, period.averageSteps)),
      label: l10n.walkAverageSteps,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.walkGoalDaysReached(reached, elapsed.length),
          key: const Key('walk-goal-days'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _row(total, average),
      ],
    );
  }

  Widget _row(Widget left, Widget right) => Row(
    children: [
      Expanded(child: left),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: right),
    ],
  );
}

/// 아이콘 + 값 + 라벨 한 칸.
class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
