import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/one_shot_draft.dart';
import '../format/alarm_format.dart';

/// 한 번 알람 편집 영역 — 큰 "N시간 M분 뒤" · 울릴 시각 칩 · 2×2 더하기 버튼 · 초기화.
///
/// 칩을 누르면 시각 휠 시트가 떠서 고른 시각으로 고정한다([onFixAt]). [now] 는 화면이
/// 매분 0초에 새로 넘긴다 — 상대 모드면 울릴 시각이, 고정 모드면 남은 시간이 바뀐다.
class OneShotSection extends StatelessWidget {
  const OneShotSection({
    required this.draft,
    required this.now,
    required this.onAdd,
    required this.onReset,
    required this.onFixAt,
    this.enabled = true,
    super.key,
  });

  final OneShotDraft draft;
  final DateTime now;
  final ValueChanged<Duration> onAdd;
  final VoidCallback onReset;
  final void Function(int hour, int minute) onFixAt;

  /// 저장 · 삭제 중이면 false — 버튼을 잠근다.
  final bool enabled;

  Future<void> _pickTime(BuildContext context) async {
    final ringAt = draft.ringAt(now);
    final picked = await OneShotTimeSheet.show(
      context,
      initial: TimeOfDay(hour: ringAt.hour, minute: ringAt.minute),
    );
    if (picked != null) onFixAt(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remaining = draft.remaining(now);
    final ringAt = draft.ringAt(now);
    final duration = remaining == Duration.zero
        ? l10n.walkAlarmDurationMinutes(0)
        : AlarmFormat.duration(l10n, remaining);

    Widget step(Duration d) => Expanded(
      child: AppButton.secondary(
        label: d.inHours > 0 ? l10n.walkAlarmAddHour(d.inHours) : l10n.walkAlarmAddMinutes(d.inMinutes),
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerLow,
          side: BorderSide.none,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          textStyle: theme.textTheme.titleMedium,
        ),
        onPressed: enabled ? () => onAdd(d) : null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.walkAlarmAfter(duration),
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: ActionChip(
            avatar: Icon(Icons.alarm, color: colorScheme.onPrimaryContainer),
            label: Text(
              l10n.walkAlarmRingsAtChip(AlarmFormat.time(context, ringAt.hour, ringAt.minute)),
            ),
            labelStyle: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer),
            backgroundColor: colorScheme.primaryContainer,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            onPressed: enabled ? () => _pickTime(context) : null,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(children: [step(oneShotSteps[0]), const SizedBox(width: AppSpacing.sm), step(oneShotSteps[1])]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [step(oneShotSteps[2]), const SizedBox(width: AppSpacing.sm), step(oneShotSteps[3])]),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: AppButton.text(
            label: l10n.walkAlarmReset,
            onPressed: enabled && draft != const OneShotDraft() ? onReset : null,
          ),
        ),
      ],
    );
  }
}

/// 한 번 알람의 울릴 시각을 휠로 고르는 바텀시트. 확인하면 고른 시각을, 닫으면 null.
class OneShotTimeSheet extends StatefulWidget {
  const OneShotTimeSheet({required this.initial, super.key});

  final TimeOfDay initial;

  /// 시각 휠 높이 — 다섯 줄 남짓이 보이는 크기. 여백 토큰이 아니라 휠 자체의 크기다.
  static const pickerHeight = 200.0;

  static Future<TimeOfDay?> show(BuildContext context, {required TimeOfDay initial}) =>
      showModalBottomSheet<TimeOfDay>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => OneShotTimeSheet(initial: initial),
      );

  @override
  State<OneShotTimeSheet> createState() => _OneShotTimeSheetState();
}

class _OneShotTimeSheetState extends State<OneShotTimeSheet> {
  late TimeOfDay _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: OneShotTimeSheet.pickerHeight,
              // 편집 화면의 반복 휠과 같은 Cupertino 휠(이유는 RepeatSection 참고).
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                initialDateTime: DateTime(2000, 1, 1, widget.initial.hour, widget.initial.minute),
                onDateTimeChanged: (value) =>
                    setState(() => _value = TimeOfDay(hour: value.hour, minute: value.minute)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: l10n.walkAlarmPickTimeConfirm,
              onPressed: () => Navigator.of(context).pop(_value),
            ),
          ],
        ),
      ),
    );
  }
}
