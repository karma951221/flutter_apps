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
import 'today_goal_footer.dart';

/// 오늘 걸음을 목표 링으로 보여 주는 카드. 링을 누르면 아래 줄이 남은(넘친) 양으로 바뀌고,
/// 3초 뒤 또는 다시 누르면 거리 · 칼로리로 돌아온다.
class TodayGoalCard extends StatefulWidget {
  const TodayGoalCard({
    required this.activity,
    required this.goal,
    this.celebrate = false,
    this.onCelebrated,
    super.key,
  });

  final DailyActivity activity;
  final int goal;

  /// 거짓 → 참이 되는 순간(또는 참으로 처음 그려질 때) 축하 연출을 한 번 한다.
  final bool celebrate;

  /// 연출을 시작한 직후 불린다. 부모가 [celebrate] 를 거두는 데 쓴다.
  final VoidCallback? onCelebrated;

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
                  // 날이 바뀌면 새 연출 상태로 — 어제 연출한 채 오늘 달성 값이 바로 와도 놓치지 않는다.
                  key: ValueKey(DateUtils.dateOnly(activity.date)),
                  play: widget.celebrate,
                  onPlayed: widget.onCelebrated,
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
            TodayGoalFooter(
              activity: activity,
              goal: widget.goal,
              showRemaining: _showRemaining,
            ),
          ],
        ),
      ),
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
