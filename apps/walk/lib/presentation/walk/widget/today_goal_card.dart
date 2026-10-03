import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/daily_activity.dart';
import '../../../domain/walk/entity/goal_progress.dart';
import '../../theme/walk_motion.dart';
import '../format/walk_format.dart';
import 'goal_celebration.dart';
import 'step_goal_ring.dart';

/// 오늘 걸음을 목표 링으로 보여 주는 카드. 링을 누르면 아래 줄이 남은(넘친) 양으로 바뀌고,
/// 3초 뒤 또는 다시 누르면 거리 · 칼로리로 돌아온다.
class TodayGoalCard extends StatefulWidget {
  const TodayGoalCard({
    required this.activity,
    required this.goal,
    this.celebrate = false,
    super.key,
  });

  final DailyActivity activity;
  final int goal;

  /// 참이 되는 첫 순간 한 번 축하 연출을 한다.
  final bool celebrate;

  @override
  State<TodayGoalCard> createState() => _TodayGoalCardState();
}

class _TodayGoalCardState extends State<TodayGoalCard> {
  static const _remainingFor = Duration(seconds: 3);

  bool _showRemaining = false;
  Timer? _timer;

  void _toggle() {
    _timer?.cancel();
    setState(() => _showRemaining = !_showRemaining);
    if (_showRemaining) {
      _timer = Timer(_remainingFor, () {
        if (mounted) setState(() => _showRemaining = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onPrimaryContainer;
    final activity = widget.activity;
    final progress = GoalProgress(steps: activity.steps, goal: widget.goal);
    String steps(int n) => l10n.walkStepsCount(WalkFormat.steps(locale, n));

    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  l10n.walkToday,
                  style: theme.textTheme.titleMedium?.copyWith(color: onCard),
                ),
                const Spacer(),
                if (progress.reached) const _ReachedBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              key: const Key('walk-goal-ring'),
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Semantics(
                label: l10n.walkGoalRingSemantics(
                  steps(activity.steps),
                  steps(widget.goal),
                  (progress.ratio * 100).round(),
                ),
                excludeSemantics: true,
                child: GoalCelebration(
                  play: widget.celebrate,
                  child: StepGoalRing(
                    ratio: progress.ratio,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CountUp(
                          steps: activity.steps,
                          format: steps,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: onCard,
                          ),
                        ),
                        Text(
                          l10n.walkGoalOf(steps(widget.goal)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onCard,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedSwitcher(
              duration: WalkMotion.off(context)
                  ? Duration.zero
                  : WalkMotion.short,
              child: _showRemaining
                  ? Text(
                      _remainingLine(l10n, locale, progress, steps),
                      key: const ValueKey('remaining'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onCard,
                      ),
                    )
                  : Row(
                      key: const ValueKey('metrics'),
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Metric(
                          label: l10n.walkDistance,
                          value: WalkFormat.distance(
                            locale,
                            activity.distanceMeters,
                          ),
                        ),
                        _Metric(
                          label: l10n.walkActiveCalories,
                          value: WalkFormat.kcal(locale, activity.activeKcal),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _remainingLine(
    AppLocalizations l10n,
    String locale,
    GoalProgress progress,
    String Function(int) steps,
  ) {
    if (progress.reached) {
      return l10n.walkGoalExceeded(steps(progress.overSteps));
    }
    final meters = progress.remainingMeters(widget.activity.distanceMeters);
    final remaining = steps(progress.remainingSteps);
    return meters == null
        ? l10n.walkGoalRemaining(remaining)
        : l10n.walkGoalRemainingWithDistance(
            remaining,
            WalkFormat.distance(locale, meters),
          );
  }
}

/// 걸음 수를 직전 값에서 새 값까지 세어 올린다(처음엔 0 부터). 마지막 프레임은 항상 [steps].
class _CountUp extends StatelessWidget {
  const _CountUp({required this.steps, required this.format, this.style});

  final int steps;
  final String Function(int) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(begin: 0, end: steps),
    duration: WalkMotion.off(context) ? Duration.zero : WalkMotion.long,
    curve: WalkMotion.emphasized,
    builder: (context, value, _) =>
        Text(format(value), key: const Key('walk-today-steps'), style: style),
  );
}

class _ReachedBadge extends StatelessWidget {
  const _ReachedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: WalkMotion.off(context) ? Duration.zero : WalkMotion.medium,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).walkGoalReached,
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
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
    final color = theme.colorScheme.onPrimaryContainer;
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
