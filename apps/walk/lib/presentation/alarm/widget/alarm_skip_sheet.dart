import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/upcoming_triggers.dart';
import '../format/alarm_format.dart';

/// 건너뛰기 시트에서 고른 동작.
enum AlarmSkipAction { skip, unskip }

/// 반복 알람 행을 길게 누르거나 "공휴일" 칩을 누르면 뜨는 시트(웨이브 3 스펙 §2 B1).
/// 손잡이 · 알람(시각 · 제목) · 한 행 — 건너뛰지 않았으면 [다음 알람 건너뛰기 · 다음 회차],
/// 건너뛰었으면 [건너뛰기 취소 · 건너뛴 회차]. 고르면 그 동작을, 그냥 닫으면 null 을 돌려준다.
class AlarmSkipSheet extends StatelessWidget {
  const AlarmSkipSheet({required this.alarm, required this.now, super.key});

  final Alarm alarm;

  /// 다음 회차 · 오늘/내일 표기의 기준 시각.
  final DateTime now;

  static Future<AlarmSkipAction?> show(
    BuildContext context, {
    required Alarm alarm,
    required DateTime now,
  }) => showModalBottomSheet<AlarmSkipAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AlarmSkipSheet(alarm: alarm, now: now),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final time = AlarmFormat.time(context, alarm.hour, alarm.minute);
    final skippedAt = alarm.skippedAt;
    // use case 의 skipNext 와 같은 회차 — 건너뛰기를 뺀 규칙의 다음 회차.
    final at = skippedAt ?? upcomingTriggers(alarm, now).firstOrNull;
    final (title, icon, action) = skippedAt == null
        ? (l10n.walkAlarmSkipNext, Icons.skip_next, AlarmSkipAction.skip)
        : (l10n.walkAlarmUnskip, Icons.undo, AlarmSkipAction.unskip);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                alarm.label.isEmpty ? time : '$time ${alarm.label}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.lgAll,
              clipBehavior: Clip.antiAlias,
              child: AppListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Icon(icon),
                ),
                title: Text(title),
                subtitle: at == null ? null : Text(AlarmFormat.ringAt(context, at, now)),
                onTap: () => Navigator.of(context).pop(action),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
