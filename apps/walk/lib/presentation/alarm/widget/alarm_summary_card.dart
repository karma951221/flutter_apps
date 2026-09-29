import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../format/alarm_format.dart';

/// 알람 목록 맨 위 요약 — 가장 먼저 울릴 알람까지 남은 시간과 그 날 · 시각 · 라벨.
/// 알람이 모두 꺼져 있으면 `켜진 알람이 없어요` 한 줄, 켜진 알람은 있는데 예약이 없으면
/// (권한 거부 등) `예약된 알람이 없어요` + `권한을 확인하세요`. 누를 수 없다.
/// 알람이 하나도 없을 때는 목록이 이 카드를 두지 않는다.
///
/// 모양은 걷기 탭의 `TodayActivityCard` 와 같은 테마 `Card` 다.
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

    final List<Widget> lines;
    if (id == null && alarms.any((a) => a.enabled)) {
      // 켜진 알람은 있는데 걸린 예약이 없다 — 대개 권한 거부(배너가 위에 함께 보인다).
      lines = [
        Text(l10n.walkAlarmNoneScheduled, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.walkAlarmNoneScheduledHint,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ];
    } else if (id == null) {
      lines = [Text(l10n.walkAlarmNoneEnabled, style: theme.textTheme.titleMedium)];
    } else {
      final at = nextAt[id]!;
      final label = alarms.where((a) => a.id == id).firstOrNull?.label ?? '';
      final when = AlarmFormat.ringAt(context, at, now);
      lines = [
        Text(l10n.walkAlarmNextTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AlarmFormat.remaining(l10n, at.difference(now)),
          key: const Key('alarm-summary-remaining'),
          style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label.isEmpty ? when : '$when · $label',
          key: const Key('alarm-summary-when'),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ];
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
      ),
    );
  }
}
