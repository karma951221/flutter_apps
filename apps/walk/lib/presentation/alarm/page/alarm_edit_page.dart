import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../cubit/alarm_edit_cubit.dart';
import '../cubit/alarm_edit_state.dart';
import '../format/alarm_format.dart';
import '../format/alarm_sound_format.dart';
import 'alarm_sound_page.dart';

/// 새 알람 · 알람 편집. 저장하면 울릴 때까지 남은 시간을 결과로 돌려주며 닫힌다
/// (목록이 스낵바를 띄운다). 삭제하거나 그냥 닫으면 결과는 null.
class AlarmEditPage extends StatefulWidget {
  const AlarmEditPage({required this.initial, super.key});

  final Alarm initial;

  @override
  State<AlarmEditPage> createState() => _AlarmEditPageState();
}

class _AlarmEditPageState extends State<AlarmEditPage> {
  late final _cubit = AlarmEditCubit(
    getIt<AlarmUseCase>(),
    getIt<AlarmPermissions>(),
    getIt<Clock>(),
    widget.initial,
  );
  late final _label = TextEditingController(text: widget.initial.label);

  /// 시각 휠 높이 — 다섯 줄 남짓이 보이는 크기. 여백 토큰이 아니라 휠 자체의 크기다.
  static const _pickerHeight = 200.0;
  static const _labelMaxLength = 30;

  @override
  void dispose() {
    _cubit.close();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    try {
      final untilRing = await _cubit.save();
      if (mounted) Navigator.of(context).pop(untilRing);
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(context, message: l10n.walkAlarmSaveFailed, type: AppSnackBarType.error);
    }
  }

  Future<void> _pickSound() async {
    final sound = await Navigator.of(context).push<AlarmSound>(
      MaterialPageRoute(builder: (_) => AlarmSoundPage(initial: _cubit.state.alarm.sound)),
    );
    if (sound != null) _cubit.setSound(sound);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkAlarmDeleteTitle,
      content: l10n.walkAlarmDeleteContent,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      await _cubit.delete();
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(context, message: l10n.walkAlarmSaveFailed, type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocBuilder<AlarmEditCubit, AlarmEditState>(
      bloc: _cubit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(state.isNew ? l10n.walkAlarmNew : l10n.walkAlarmEdit)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              SizedBox(
                height: _pickerHeight,
                // Material 의 `showTimePicker` 는 다이얼로그라 화면 안에 휠을 둘 수 없다.
                // 알람 앱의 익숙한 휠 모양을 위해 Cupertino 위젯을 직접 쓴다.
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                  initialDateTime: DateTime(2000, 1, 1, widget.initial.hour, widget.initial.minute),
                  onDateTimeChanged: (value) => _cubit.setTime(value.hour, value.minute),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.walkAlarmRepeat, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final day in Weekday.values) ...[
                    if (day != Weekday.values.first) const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _WeekdayToggle(
                        label: AlarmFormat.weekday(l10n.localeName, day),
                        selected: state.alarm.repeat.contains(day),
                        onTap: () => _cubit.toggleDay(day),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AlarmFormat.repeat(l10n, state.alarm.repeat),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _label,
                maxLength: _labelMaxLength,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.walkAlarmLabel,
                  hintText: l10n.walkAlarmLabelHint,
                ),
                onChanged: _cubit.setLabel,
              ),
              AppListTile(
                title: Text(l10n.walkAlarmSound),
                subtitle: Text(AlarmSoundFormat.name(l10n, state.alarm.sound)),
                trailing: const Icon(Icons.chevron_right),
                onTap: state.busy ? null : _pickSound,
              ),
              AppListTile(
                title: Text(l10n.walkAlarmVibrate),
                trailing: Switch(
                  value: state.alarm.vibrate,
                  onChanged: state.busy ? null : _cubit.setVibrate,
                ),
                onTap: state.busy ? null : () => _cubit.setVibrate(!state.alarm.vibrate),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: l10n.commonSave,
                isLoading: state.busy,
                onPressed: _save,
              ),
              if (!state.isNew) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton.text(
                  label: l10n.commonDelete,
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  onPressed: state.busy ? null : _delete,
                ),
              ],
            ],
          ),
        ),
      ),
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
          color: selected ? colorScheme.primary : Colors.transparent,
          shape: CircleBorder(
            side: selected
                ? BorderSide.none
                : BorderSide(color: colorScheme.outline),
          ),
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
