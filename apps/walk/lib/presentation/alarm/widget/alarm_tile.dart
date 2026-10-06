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
    final colorScheme = theme.colorScheme;
    final dimmed = alarm.enabled ? null : colorScheme.onSurfaceVariant;
    final summary = alarm.isOneShot
        ? alarm.label
        : alarm.label.isEmpty
        ? AlarmFormat.repeat(l10n, alarm.repeat)
        : '${alarm.label} · ${AlarmFormat.repeat(l10n, alarm.repeat)}';
    final untilRing = alarm.enabled ? this.untilRing : null;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      _OneShotLine(untilRing: untilRing, color: dimmed ?? colorScheme.primary)
                    else
                      WeekdayDots(days: alarm.repeat, dimmed: !alarm.enabled),
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

/// 한 번 알람의 종류 줄 — 모래시계 + `한 번 · N 뒤`(남은 시간을 모르면 `한 번`).
class _OneShotLine extends StatelessWidget {
  const _OneShotLine({required this.untilRing, required this.color});

  final Duration? untilRing;
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
            untilRing == null
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
