import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/repeat_preset.dart';
import '../format/alarm_format.dart';

/// 반복 알람 편집 영역 — 시각 휠 · 빠른 버튼(매일 · 평일 · 주말) · 요일 원 7개 · 반복 요약.
///
/// 빠른 버튼은 지금 요일 집합이 그 묶음과 같을 때 채워진다. 요일이 하나도 없으면 요약 줄을
/// 두지 않는다(화면이 저장을 잠그고 안내한다).
class RepeatSection extends StatelessWidget {
  const RepeatSection({
    required this.initialHour,
    required this.initialMinute,
    required this.repeat,
    required this.onTimeChanged,
    required this.onToggleDay,
    required this.onPreset,
    super.key,
  });

  /// 휠의 처음 시각. 휠은 스스로 값을 들고 있어 처음 한 번만 쓴다.
  final int initialHour;
  final int initialMinute;
  final Set<Weekday> repeat;
  final void Function(int hour, int minute) onTimeChanged;
  final ValueChanged<Weekday> onToggleDay;
  final ValueChanged<RepeatPreset> onPreset;

  /// 시각 휠 높이 — 다섯 줄 남짓이 보이는 크기. 여백 토큰이 아니라 휠 자체의 크기다.
  static const _pickerHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final current = RepeatPreset.of(repeat);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _pickerHeight,
          // Material 의 `showTimePicker` 는 다이얼로그라 화면 안에 휠을 둘 수 없다.
          // 알람 앱의 익숙한 휠 모양을 위해 Cupertino 위젯을 직접 쓴다.
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
            initialDateTime: DateTime(2000, 1, 1, initialHour, initialMinute),
            onDateTimeChanged: (value) => onTimeChanged(value.hour, value.minute),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final preset in RepeatPreset.values)
              ChoiceChip(
                label: Text(switch (preset) {
                  RepeatPreset.everyday => l10n.walkAlarmPresetEveryday,
                  RepeatPreset.weekdays => l10n.walkAlarmPresetWeekdays,
                  RepeatPreset.weekend => l10n.walkAlarmPresetWeekend,
                }),
                selected: preset == current,
                showCheckmark: false,
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: preset == current ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
                onSelected: (_) => onPreset(preset),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final day in Weekday.values) ...[
              if (day != Weekday.values.first) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _WeekdayToggle(
                  label: AlarmFormat.weekday(l10n.localeName, day),
                  selected: repeat.contains(day),
                  onTap: () => onToggleDay(day),
                ),
              ),
            ],
          ],
        ),
        if (repeat.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            AlarmFormat.repeat(l10n, repeat),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// 요일 하나를 나타내는 원형 토글. `FilterChip` 은 내재 여백·최소 너비가 있어
/// `Expanded` 로 7개를 한 줄에 균등하게 맞추기 어려워 직접 그린다.
class _WeekdayToggle extends StatelessWidget {
  const _WeekdayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerLow,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
