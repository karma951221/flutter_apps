import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../cubit/alarm_edit_cubit.dart';
import '../cubit/alarm_edit_state.dart';
import '../format/alarm_sound_format.dart';
import '../widget/one_shot_section.dart';
import '../widget/repeat_section.dart';
import 'alarm_sound_page.dart';

/// 새 알람 · 알람 편집. 종류는 [initial] 로 정한다 — 한 번 알람이면 "얼마 뒤" 영역,
/// 반복 알람이면 시각 휠 · 요일 영역이고, 아래쪽(제목 · 알람음 · 무음 체크 · 저장)은 같다.
/// 저장하면 울릴 때까지 남은 시간을 결과로 돌려주며 닫힌다(목록이 스낵바를 띄운다).
/// 삭제하거나 그냥 닫으면 결과는 null.
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
  final _clock = getIt<Clock>();

  /// 종류는 처음 값으로 정하고 바꾸지 않는다 — 반복 알람의 요일을 다 꺼도 이 화면이다.
  late final _oneShot = widget.initial.isOneShot;

  /// 남은 시간 · 울릴 시각 · 저장 가능 여부의 기준 시각. 매분 0초에 새로 읽는다.
  late DateTime _now = _clock.now();
  Timer? _align;
  Timer? _ticker;

  static const _labelMaxLength = 30;

  @override
  void initState() {
    super.initState();
    final nextMinute = DateTime(_now.year, _now.month, _now.day, _now.hour, _now.minute + 1);
    _align = Timer(nextMinute.difference(_now), () {
      _tick();
      _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    });
  }

  void _tick() {
    if (mounted) setState(() => _now = _clock.now());
  }

  @override
  void dispose() {
    _align?.cancel();
    _ticker?.cancel();
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
      builder: (context, state) {
        final canSave = _cubit.canSave(_now);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              !state.isNew
                  ? l10n.walkAlarmEdit
                  : _oneShot
                  ? l10n.walkAlarmNewOneShot
                  : l10n.walkAlarmNewRepeat,
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_oneShot)
                  OneShotSection(
                    draft: state.draft,
                    now: _now,
                    enabled: !state.busy,
                    onAdd: _cubit.addOffset,
                    onReset: _cubit.resetOffset,
                    onFixAt: _cubit.fixOneShotAt,
                  )
                else
                  RepeatSection(
                    initialHour: widget.initial.hour,
                    initialMinute: widget.initial.minute,
                    repeat: state.alarm.repeat,
                    onTimeChanged: _cubit.setTime,
                    onToggleDay: _cubit.toggleDay,
                    onPreset: _cubit.applyPreset,
                  ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _label,
                  maxLength: _labelMaxLength,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.walkAlarmTitle,
                    hintText: l10n.walkAlarmTitleHint,
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
                  leading: Checkbox(
                    value: state.alarm.silentWhenRingerMuted,
                    onChanged: state.busy
                        ? null
                        : (value) => _cubit.setSilentWhenRingerMuted(value ?? false),
                  ),
                  title: Text(l10n.walkAlarmSilentWhenMuted),
                  subtitle: Text(l10n.walkAlarmSilentWhenMutedHint),
                  onTap: state.busy
                      ? null
                      : () => _cubit.setSilentWhenRingerMuted(!state.alarm.silentWhenRingerMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!canSave) ...[
                  Text(
                    _oneShot ? l10n.walkAlarmNeedTime : l10n.walkAlarmNeedDays,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppButton.primary(
                  label: l10n.commonSave,
                  isLoading: state.busy,
                  onPressed: canSave ? _save : null,
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
        );
      },
    );
  }
}
