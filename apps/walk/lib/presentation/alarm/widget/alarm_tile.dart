import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../format/alarm_format.dart';

/// 알람 목록 한 행 — 큰 시각 · 라벨 · 반복 요약 · 켜기 스위치. 꺼진 알람은 흐리게.
/// 켜진 알람에 [untilRing](실제 다음 울림까지)이 있으면 셋째 줄에 `N분 후`.
///
/// `AppListTile.enabled` 로 흐리게 하지 않는다 — 그러면 행 탭(편집)까지 막힌다.
class AlarmTile extends StatelessWidget {
  const AlarmTile({
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    this.untilRing,
    super.key,
  });

  final Alarm alarm;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final Duration? untilRing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dimmed = alarm.enabled ? null : theme.disabledColor;
    final repeat = AlarmFormat.repeat(l10n, alarm.repeat);
    final summary = Text(
      alarm.label.isEmpty ? repeat : '${alarm.label} · $repeat',
      style: dimmed == null ? null : TextStyle(color: dimmed),
    );
    final untilRing = alarm.enabled ? this.untilRing : null;
    return AppListTile(
      title: Text(
        AlarmFormat.time(context, alarm.hour, alarm.minute),
        style: theme.textTheme.headlineMedium?.copyWith(color: dimmed),
      ),
      subtitle: untilRing == null
          ? summary
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summary,
                Text(
                  AlarmFormat.remaining(l10n, untilRing),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
      trailing: Switch(value: alarm.enabled, onChanged: onToggle),
      onTap: onTap,
    );
  }
}
