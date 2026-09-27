import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../format/alarm_format.dart';

/// 알람 목록 한 행 — 큰 시각 · 라벨 · 반복 요약 · 켜기 스위치. 꺼진 알람은 흐리게.
///
/// `AppListTile.enabled` 로 흐리게 하지 않는다 — 그러면 행 탭(편집)까지 막힌다.
class AlarmTile extends StatelessWidget {
  const AlarmTile({
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    super.key,
  });

  final Alarm alarm;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dimmed = alarm.enabled ? null : theme.disabledColor;
    final repeat = AlarmFormat.repeat(l10n, alarm.repeat);
    return AppListTile(
      title: Text(
        AlarmFormat.time(context, alarm.hour, alarm.minute),
        style: theme.textTheme.headlineMedium?.copyWith(color: dimmed),
      ),
      subtitle: Text(
        alarm.label.isEmpty ? repeat : '${alarm.label} · $repeat',
        style: dimmed == null ? null : TextStyle(color: dimmed),
      ),
      trailing: Switch(value: alarm.enabled, onChanged: onToggle),
      onTap: onTap,
    );
  }
}
