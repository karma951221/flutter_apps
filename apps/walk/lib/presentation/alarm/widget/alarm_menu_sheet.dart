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
  }) => showAppSheet<AlarmMenuAction>(
    context: context,
    builder: (_) => AlarmMenuSheet(alarm: alarm, now: now, pause: pause),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final time = AlarmFormat.time(context, alarm.hour, alarm.minute);

    Widget row(IconData icon, String title, AlarmMenuAction action, {Widget? subtitle}) {
      // 파괴적 행은 아이콘 · 제목 모두 error 색(⋮ 메뉴 isDestructive 와 같다).
      final color = action == AlarmMenuAction.delete ? colorScheme.error : null;
      return AppListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: color == null ? null : TextStyle(color: color)),
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
          ? (l10n.walkAlarmSkipNext, Icons.skip_next_outlined, AlarmMenuAction.skip)
          : (l10n.walkAlarmUnskip, Icons.undo_outlined, AlarmMenuAction.unskip);
      return row(
        icon,
        title,
        action,
        subtitle: at == null ? null : Text(AlarmFormat.ringAt(context, at, now)),
      );
    }

    return AppSheetScaffold(
      title: alarm.label.isEmpty ? time : '$time ${alarm.label}',
      children: [
        row(Icons.content_copy_outlined, l10n.walkAlarmDuplicate, AlarmMenuAction.duplicate),
        ?skipRow(),
        row(Icons.delete_outline, l10n.commonDelete, AlarmMenuAction.delete),
      ],
    );
  }
}
