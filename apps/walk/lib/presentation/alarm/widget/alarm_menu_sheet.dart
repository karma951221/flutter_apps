import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_pause.dart';
import '../../../domain/alarm/upcoming_triggers.dart';
import '../format/alarm_format.dart';

/// 알람 메뉴 시트에서 고른 동작.
enum AlarmMenuAction { duplicate, skip, unskip, delete }

/// 알람 행을 길게 누르거나 "공휴일" 칩을 누르면 뜨는 알람 메뉴(웨이브 4 스펙 §5 —
/// 웨이브 3 의 건너뛰기 시트를 모든 알람용으로 넓혔다).
/// 손잡이 · 알람(시각 · 제목) · [복제] · (건너뛸 수 있으면) [다음 알람 건너뛰기 · 다음 회차] 또는
/// [건너뛰기 취소 · 건너뛴 회차] · [삭제]. 고르면 그 동작을, 그냥 닫으면 null 을 돌려준다.
/// 삭제 확인은 부르는 쪽이 한다.
class AlarmMenuSheet extends StatelessWidget {
  const AlarmMenuSheet({required this.alarm, required this.now, this.pause, super.key});

  final Alarm alarm;

  /// 다음 회차 · 오늘/내일 표기의 기준 시각.
  final DateTime now;

  /// 쉬는 기간. 다음 회차는 이 기간을 뺀, 실제로 울릴 회차다.
  final AlarmPause? pause;

  /// 건너뛰기 행을 보이는 알람 — 켜진 반복 알람, 또는 건너뛴 값이 남은 반복 알람(취소).
  static bool canSkip(Alarm alarm) =>
      !alarm.isOneShot && (alarm.enabled || alarm.skippedAt != null);

  static Future<AlarmMenuAction?> show(
    BuildContext context, {
    required Alarm alarm,
    required DateTime now,
    AlarmPause? pause,
  }) => showModalBottomSheet<AlarmMenuAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AlarmMenuSheet(alarm: alarm, now: now, pause: pause),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final time = AlarmFormat.time(context, alarm.hour, alarm.minute);

    Widget row(IconData icon, String title, AlarmMenuAction action, {Widget? subtitle}) {
      final destructive = action == AlarmMenuAction.delete;
      return AppListTile(
        leading: CircleAvatar(
          backgroundColor: destructive ? colorScheme.errorContainer : colorScheme.primaryContainer,
          foregroundColor: destructive
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: destructive ? TextStyle(color: colorScheme.error) : null),
        subtitle: subtitle,
        onTap: () => Navigator.of(context).pop(action),
      );
    }

    Widget? skipRow() {
      if (!canSkip(alarm)) return null;
      final skippedAt = alarm.skippedAt;
      // use case 의 skipNext 와 같은 회차 — 건너뛰기 · 쉬는 기간을 뺀 규칙의 다음 회차.
      final at = skippedAt ?? upcomingTriggers(alarm, now, pause: pause).firstOrNull;
      final (title, icon, action) = skippedAt == null
          ? (l10n.walkAlarmSkipNext, Icons.skip_next, AlarmMenuAction.skip)
          : (l10n.walkAlarmUnskip, Icons.undo, AlarmMenuAction.unskip);
      return row(
        icon,
        title,
        action,
        subtitle: at == null ? null : Text(AlarmFormat.ringAt(context, at, now)),
      );
    }

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  row(Icons.content_copy, l10n.walkAlarmDuplicate, AlarmMenuAction.duplicate),
                  ?skipRow(),
                  row(Icons.delete_outline, l10n.commonDelete, AlarmMenuAction.delete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
