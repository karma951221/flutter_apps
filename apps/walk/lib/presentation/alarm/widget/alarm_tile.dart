import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../format/alarm_format.dart';
import 'weekday_dots.dart';

/// 알람 목록 한 행 — 둥근 카드 안에 큰 시각(오전/오후는 작게) · `제목 · 반복 요약` · 종류 줄과
/// 오른쪽 켜기 스위치. 종류 줄은 반복 알람이면 요일 점 7개, 한 번 알람이면 모래시계 + `한 번 · N 뒤`
/// (켜져 있고 [untilRing] 이 있을 때. 아니면 `한 번`). 꺼진 알람은 글자를 흐리게.
///
/// 한 번 알람은 종류 줄이 반복 요약을 대신하므로 둘째 줄은 제목만(없으면 줄째 생략).
///
/// 켜진 반복 알람의 요일 점 옆에 칩: 다음 회차를 건너뛰었으면 "건너뜀", 다음 울림이 24시간 안
/// 공휴일이면([holidayName]) "공휴일"(누르면 [onHolidayTap] — 건너뛰기 시트).
///
/// 쉬는 기간 때문에 예약이 없는 켜진 알람([pausedOut])은 한 번 알람이면 종류 줄이 `한 번 · 쉬는 중`,
/// 반복 알람이면 요일 점 옆에 "쉬는 중" 칩 — 울리지 않을 것을 행에서 알 수 있게.
class AlarmTile extends StatelessWidget {
  const AlarmTile({
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    this.untilRing,
    this.onLongPress,
    this.holidayName,
    this.onHolidayTap,
    this.pausedOut = false,
    super.key,
  });

  final Alarm alarm;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final Duration? untilRing;

  /// 반복 알람의 건너뛰기 시트. null 이면 길게 누르기가 없다.
  final VoidCallback? onLongPress;

  /// 다음 울림 날의 공휴일 이름. null 이면 "공휴일" 칩이 없다.
  final String? holidayName;
  final VoidCallback? onHolidayTap;

  /// 쉬는 기간 때문에 예약이 없다(켜져 있을 때만 보인다).
  final bool pausedOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dimmed = alarm.enabled ? null : colorScheme.onSurfaceVariant;
    final summary = alarm.isOneShot
        ? alarm.label
        : alarm.label.isEmpty
        ? AlarmFormat.repeat(l10n, alarm.repeat)
        : '${alarm.label} · ${AlarmFormat.repeat(l10n, alarm.repeat)}';
    final untilRing = alarm.enabled ? this.untilRing : null;
    final pausedOut = alarm.enabled && this.pausedOut;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Time(alarm: alarm, color: dimmed),
                    if (summary.isNotEmpty)
                      Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: dimmed),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    if (alarm.isOneShot)
                      _OneShotLine(
                        untilRing: untilRing,
                        pausedOut: pausedOut,
                        color: dimmed ?? colorScheme.primary,
                      )
                    else
                      // 칩이 붙으면 좁은 폭에서 다음 줄로 넘긴다.
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          WeekdayDots(days: alarm.repeat, dimmed: !alarm.enabled),
                          if (pausedOut)
                            _TileChip(label: l10n.walkAlarmPausedOutRow, icon: Icons.bedtime),
                          if (alarm.enabled && alarm.skippedAt != null)
                            _TileChip(label: l10n.walkAlarmSkipped, icon: Icons.skip_next),
                          if (alarm.enabled && holidayName != null)
                            _TileChip(
                              label: l10n.walkAlarmHolidayChip,
                              icon: Icons.event,
                              tooltip: holidayName,
                              onPressed: onHolidayTap,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              Switch(
                value: alarm.enabled,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onToggle(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 행 안의 작은 칩. [onPressed] 가 있으면 누를 수 있다.
class _TileChip extends StatelessWidget {
  const _TileChip({required this.label, required this.icon, this.tooltip, this.onPressed});

  final String label;
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatar = Icon(icon, color: colorScheme.onSecondaryContainer);
    final text = Text(label);
    const density = VisualDensity(horizontal: -4, vertical: -4);
    final onPressed = this.onPressed;
    return onPressed == null
        ? Chip(
            avatar: avatar,
            label: text,
            visualDensity: density,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: colorScheme.secondaryContainer,
            side: BorderSide.none,
          )
        : ActionChip(
            avatar: avatar,
            label: text,
            tooltip: tooltip,
            visualDensity: density,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: colorScheme.secondaryContainer,
            side: BorderSide.none,
            onPressed: onPressed,
          );
  }
}

/// 큰 시각. 12시간제면 오전/오후 표기만 작게 — 글 전체는 [AlarmFormat.time] 과 같다.
class _Time extends StatelessWidget {
  const _Time({required this.alarm, required this.color});

  final Alarm alarm;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = AlarmFormat.time(context, alarm.hour, alarm.minute);
    final localizations = MaterialLocalizations.of(context);
    final period = alarm.hour < 12
        ? localizations.anteMeridiemAbbreviation
        : localizations.postMeridiemAbbreviation;
    final at = MediaQuery.alwaysUse24HourFormatOf(context) ? -1 : full.indexOf(period);
    final small = theme.textTheme.titleMedium?.copyWith(color: color);
    final spans = at < 0
        ? [TextSpan(text: full)]
        : [
            if (at > 0) TextSpan(text: full.substring(0, at)),
            TextSpan(text: period, style: small),
            if (at + period.length < full.length)
              TextSpan(text: full.substring(at + period.length)),
          ];
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: color),
    );
  }
}

/// 한 번 알람의 종류 줄 — 모래시계 + `한 번 · N 뒤`(쉬는 기간 때문에 예약이 없으면 `한 번 · 쉬는 중`,
/// 남은 시간을 모르면 `한 번`).
class _OneShotLine extends StatelessWidget {
  const _OneShotLine({required this.untilRing, required this.pausedOut, required this.color});

  final Duration? untilRing;
  final bool pausedOut;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: color);
    final untilRing = this.untilRing;
    return Row(
      children: [
        Icon(Icons.hourglass_bottom, size: style?.fontSize, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            pausedOut
                ? l10n.walkAlarmOneShotRow(l10n.walkAlarmPausedOutRow)
                : untilRing == null
                ? l10n.walkAlarmKindOneShot
                : l10n.walkAlarmOneShotRow(
                    l10n.walkAlarmAfter(AlarmFormat.duration(l10n, untilRing)),
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
