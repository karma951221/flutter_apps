import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/holiday/holiday_calendar_access.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../cubit/alarm_edit_cubit.dart';
import '../cubit/alarm_edit_state.dart';
import '../format/alarm_sound_format.dart';
import '../widget/one_shot_section.dart';
import '../widget/repeat_section.dart';
import '../widget/ring_settings_section.dart';
import 'alarm_sound_page.dart';

/// 새 알람 · 알람 편집. 종류는 [initial] 로 정한다 — 한 번 알람이면 "얼마 뒤" 영역,
/// 반복 알람이면 시각 휠 · 요일 영역이고, 아래쪽(제목 · 알람음 · 무음 체크 · 접힌 울림 설정 ·
/// 저장)은 같다.
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
    holidayCalendar: getIt<HolidayCalendarAccess>(),
  );
  late final _label = TextEditingController(text: widget.initial.label);
  final _clock = getIt<Clock>();

  /// 종류는 처음 값으로 정하고 바꾸지 않는다 — 반복 알람의 요일을 다 꺼도 이 화면이다.
  late final _oneShot = widget.initial.isOneShot;

  /// 남은 시간 · 울릴 시각 · 저장 가능 여부의 기준 시각. 매분 0초와, 고정 모드에서 남은 시간이
  /// 1분 밑으로 내려가는 순간에 새로 읽는다. 울릴 시각을 바꾸거나 저장할 때도 새로 읽는다.
  late DateTime _now = _clock.now();
  Timer? _refresh;

  static const _labelMaxLength = 30;

  @override
  void initState() {
    super.initState();
    _scheduleRefresh();
  }

  /// 다음 분 0초, 고정 모드면 저장이 잠기는 순간 중 먼저 오는 때에 [_refreshNow] 를 건다.
  void _scheduleRefresh() {
    _refresh?.cancel();
    final now = _now;
    var next = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final fixedAt = _oneShot ? _cubit.state.draft.fixedAt : null;
    if (fixedAt != null) {
      // canSave 는 1분 "이상"이라 정확히 1분 남은 순간은 아직 저장할 수 있다 — 그 바로 뒤.
      final lock = fixedAt.subtract(const Duration(minutes: 1)).add(const Duration(milliseconds: 1));
      if (lock.isAfter(now) && lock.isBefore(next)) next = lock;
    }
    _refresh = Timer(next.difference(now), () {
      if (mounted) _refreshNow();
    });
  }

  void _refreshNow() {
    setState(() => _now = _clock.now());
    _scheduleRefresh();
  }

  /// 울릴 시각이 바뀌면 기준 시각도 새로 읽는다 — 고른 시각이 1분 안이면 바로 잠긴다.
  void _editDraft(VoidCallback edit) {
    edit();
    _refreshNow();
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _cubit.close();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    // 버튼은 마지막 기준 시각으로 켜졌다. 지금 시각으로 다시 보고, 1분 미만이면 저장하지 않고
    // 잠금 · 안내로 돌린다(cubit 은 같은 판단에서 던진다).
    _refreshNow();
    if (!_cubit.canSave(_now)) return;
    try {
      final untilRing = await _cubit.save();
      if (mounted) Navigator.of(context).pop(untilRing);
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(context, message: l10n.walkAlarmSaveFailed, type: AppSnackBarType.error);
    }
  }

  Future<void> _pickSound() async {
    // 제목을 입력하던 중이면 포커스를 푼다 — 그대로 두면 선택 화면에서 돌아올 때 라우트가
    // 제목 칸에 포커스를 되돌려 키보드가 다시 올라온다. 범위(scope) 노드가 아니라 포커스를 쥔
    // 노드를 풀어야 이 화면 범위의 포커스 기록도 비워진다.
    FocusManager.instance.primaryFocus?.unfocus();
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
                    onAdd: (step) => _editDraft(() => _cubit.addOffset(step)),
                    onReset: () => _editDraft(_cubit.resetOffset),
                    onFixAt: (hour, minute) => _editDraft(() => _cubit.fixOneShotAt(hour, minute)),
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
                RingSettingsSection(
                  alarm: state.alarm,
                  enabled: !state.busy,
                  onVolumePercent: _cubit.setVolumePercent,
                  onFadeSeconds: _cubit.setFadeSeconds,
                  onSnoozeMinutes: _cubit.setSnoozeMinutes,
                  onSnoozeLimit: _cubit.setSnoozeLimit,
                  onAutoStopMinutes: _cubit.setAutoStopMinutes,
                  onRemindBefore: _cubit.setRemindBefore,
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
