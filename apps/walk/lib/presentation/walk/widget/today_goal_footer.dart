import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/daily_activity.dart';
import '../../../domain/walk/entity/goal_progress.dart';
import '../format/walk_format.dart';

/// 오늘 카드 맨 아래 한 줄 — 목표까지 남은 걸음, 달성했으면 넘친 걸음.
class TodayGoalFooter extends StatelessWidget {
  const TodayGoalFooter({
    required this.activity,
    required this.goal,
    super.key,
  });

  final DailyActivity activity;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final progress = GoalProgress(steps: activity.steps, goal: goal);
    String steps(int n) => l10n.walkStepsCount(WalkFormat.steps(locale, n));
    return Text(
      progress.reached
          ? l10n.walkGoalExceeded(steps(progress.overSteps))
          : l10n.walkGoalRemaining(steps(progress.remainingSteps)),
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
