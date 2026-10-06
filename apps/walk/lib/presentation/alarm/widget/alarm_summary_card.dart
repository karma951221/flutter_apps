import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../theme/walk_motion.dart';
import '../format/alarm_format.dart';

/// 알람 목록 맨 위 요약 — 가장 먼저 울릴 알람까지 남은 시간과 그 날 · 시각 · 라벨.
/// 알람이 모두 꺼져 있으면 `켜진 알람이 없어요` 한 줄, 켜진 알람은 있는데 예약이 없으면
/// (권한 거부 등) `예약된 알람이 없어요` + `권한을 확인하세요`. 누를 수 없다.
/// 알람이 하나도 없을 때는 목록이 이 카드를 두지 않는다.
///
/// 모양은 걷기 탭의 `TodayGoalCard` 와 같은 초록 컨테이너 `Card` 다.
/// 남은 시간 숫자가 바뀌면 아래에서 위로 밀려 오르며 바뀐다.
class AlarmSummaryCard extends StatelessWidget {
  const AlarmSummaryCard({
    required this.alarms,
    required this.nextAt,
    required this.now,
    super.key,
  });

  final List<Alarm> alarms;
  final Map<int, DateTime> nextAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final id = AlarmFormat.earliest(nextAt);
    final onCard = theme.colorScheme.onPrimaryContainer;

    final List<Widget> lines;
    if (id == null && alarms.any((a) => a.enabled)) {
      // 켜진 알람은 있는데 걸린 예약이 없다 — 대개 권한 거부(배너가 위에 함께 보인다).
      lines = [
        Text(
          l10n.walkAlarmNoneScheduled,
          style: theme.textTheme.titleMedium?.copyWith(color: onCard),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.walkAlarmNoneScheduledHint,
          style: theme.textTheme.bodyMedium?.copyWith(color: onCard),
        ),
      ];
    } else if (id == null) {
      lines = [
        Text(
          l10n.walkAlarmNoneEnabled,
          style: theme.textTheme.titleMedium?.copyWith(color: onCard),
        ),
      ];
    } else {
      final at = nextAt[id]!;
      final label = alarms.where((a) => a.id == id).firstOrNull?.label ?? '';
      final when = AlarmFormat.ringAt(context, at, now);
      final remaining = AlarmFormat.remaining(l10n, at.difference(now));
      lines = [
        Text(
          l10n.walkAlarmNextTitle,
          style: theme.textTheme.titleMedium?.copyWith(color: onCard),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSwitcher(
          duration: WalkMotion.off(context) ? Duration.zero : WalkMotion.short,
          transitionBuilder: _slideUp,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, ?current],
          ),
          child: KeyedSubtree(
            key: ValueKey(remaining),
            child: Text(
              remaining,
              key: const Key('alarm-summary-remaining'),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: onCard,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label.isEmpty ? when : '$when · $label',
          key: const Key('alarm-summary-when'),
          style: theme.textTheme.bodyMedium?.copyWith(color: onCard),
        ),
      ];
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
      ),
    );
  }

  /// 새 숫자는 아래에서 올라오고 옛 숫자는 위로 사라진다(`AnimatedSwitcher` 는 퇴장을 역재생한다).
  static Widget _slideUp(Widget child, Animation<double> animation) => SlideTransition(
        position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      );
}
