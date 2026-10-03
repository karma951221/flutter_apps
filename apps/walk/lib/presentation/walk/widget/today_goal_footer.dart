import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/daily_activity.dart';
import '../../../domain/walk/entity/goal_progress.dart';
import '../../theme/walk_motion.dart';
import '../format/walk_format.dart';

/// 오늘 카드 맨 아래 — 거리 · 칼로리 지표 ↔ 남은(넘친) 양 한 줄.
/// 지표 행은 늘 자리를 잡아 높이를 정하고, 한 줄은 그 가운데에 겹쳐 그린다 — 바뀌어도 카드가
/// 줄어들어 아래 내용이 튀지 않는다.
class TodayGoalFooter extends StatelessWidget {
  const TodayGoalFooter({
    required this.activity,
    required this.goal,
    required this.showRemaining,
    super.key,
  });

  final DailyActivity activity;
  final int goal;
  final bool showRemaining;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final duration = WalkMotion.off(context) ? Duration.zero : WalkMotion.short;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: showRemaining ? 0 : 1,
          duration: duration,
          child: IgnorePointer(
            ignoring: showRemaining,
            child: ExcludeSemantics(
              excluding: showRemaining,
              child: Row(
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
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: duration,
          child: showRemaining
              ? Text(
                  _remainingLine(l10n, locale),
                  key: const ValueKey('remaining'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
      ],
    );
  }

  String _remainingLine(AppLocalizations l10n, String locale) {
    final progress = GoalProgress(steps: activity.steps, goal: goal);
    String steps(int n) => l10n.walkStepsCount(WalkFormat.steps(locale, n));
    if (progress.reached) {
      return l10n.walkGoalExceeded(steps(progress.overSteps));
    }
    final meters = progress.remainingMeters(activity.distanceMeters);
    final remaining = steps(progress.remainingSteps);
    return meters == null
        ? l10n.walkGoalRemaining(remaining)
        : l10n.walkGoalRemainingWithDistance(
            remaining,
            WalkFormat.distance(locale, meters),
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
    final color = theme.colorScheme.onPrimaryContainer;
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
