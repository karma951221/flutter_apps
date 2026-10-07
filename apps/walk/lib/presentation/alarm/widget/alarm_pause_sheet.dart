import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm_pause.dart';
import '../format/alarm_format.dart';

/// 알람 탭 앱바 [알람 쉬기] 시트(웨이브 4 스펙 B4). 손잡이 · 제목 · 안내 · 빠른 기간
/// [오늘만 · 내일까지 · 이번 주말](각 기간을 부제로) · [날짜 고르기](기간 달력).
/// 고르면 그 기간을, 그냥 닫거나 달력을 취소하면 null 을 돌려준다.
class AlarmPauseSheet extends StatelessWidget {
  const AlarmPauseSheet({required this.now, super.key});

  /// 빠른 기간 · 오늘/내일 표기 · 달력 시작 날의 기준 시각.
  final DateTime now;

  /// 달력에서 고를 수 있는 가장 먼 날(오늘부터).
  static const pickableDays = 365;

  static Future<AlarmPause?> show(
    BuildContext context, {
    required DateTime now,
  }) => showModalBottomSheet<AlarmPause>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AlarmPauseSheet(now: now),
  );

  Future<void> _pick(BuildContext context) async {
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(now.year, now.month, now.day + pickableDays),
      currentDate: today,
      // 앱 테마의 TextButton 은 폭을 가득 채운다(`Size.fromHeight`). 달력 앱바의 [저장] 은
      // 폭이 정해지지 않은 자리라 그대로 두면 레이아웃이 깨진다 — 최소 크기만 푼다.
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            textButtonTheme: TextButtonThemeData(
              style: (theme.textButtonTheme.style ?? const ButtonStyle())
                  .copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size.zero),
                  ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(
      range == null ? null : AlarmPause(from: range.start, until: range.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget row(
      IconData icon,
      String title, {
      AlarmPause? pause,
      VoidCallback? onTap,
    }) => AppListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: pause == null
          ? null
          : Text(AlarmFormat.pauseRange(l10n, pause, now)),
      onTap: onTap ?? () => Navigator.of(context).pop(pause),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.walkAlarmPause, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.walkAlarmPauseDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
                  row(
                    Icons.today,
                    l10n.walkAlarmPauseToday,
                    pause: AlarmPause.today(now),
                  ),
                  row(
                    Icons.event,
                    l10n.walkAlarmPauseUntilTomorrow,
                    pause: AlarmPause.untilTomorrow(now),
                  ),
                  row(
                    Icons.weekend,
                    l10n.walkAlarmPauseWeekend,
                    pause: AlarmPause.weekend(now),
                  ),
                  row(
                    Icons.date_range,
                    l10n.walkAlarmPausePickDates,
                    onTap: () => _pick(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
