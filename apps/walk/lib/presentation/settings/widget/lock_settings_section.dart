import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/lock/lock_config.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../lock/page/lock_setup_page.dart';
import '../cubit/diary_settings_cubit.dart';
import 'settings_widgets.dart';

/// 잠금 행 · 다시 잠기는 시간 행 · 설명("일기와 물어보기를 함께 잠급니다").
///
/// [DiarySettingsCubit] 와 [DiaryLockCubit] 은 셸이 제공하고, 읽기([DiarySettingsCubit.load])는
/// 이 섹션을 담은 화면이 한다.
class LockSettingsSection extends StatelessWidget {
  const LockSettingsSection({super.key});

  /// 잠금 설정 화면은 일기 화면이 아니다 — 스스로 현재 비밀을 확인하므로 그냥 push 한다.
  /// 바뀌었으면(`true`) 일기 잠금에 알리고 다시 읽는다.
  Future<void> _openLockSetup(BuildContext context) async {
    final settings = context.read<DiarySettingsCubit>();
    final lock = context.read<DiaryLockCubit>();
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LockSetupPage()));
    if (changed != true) return;
    lock.configChanged();
    await settings.load();
  }

  Future<void> _pickRelock(BuildContext context, RelockDelay current) async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<DiarySettingsCubit>();
    final lock = context.read<DiaryLockCubit>();
    final picked = await SettingsChoiceSheet.show<RelockDelay>(
      context,
      title: l10n.walkDiarySettingsRelock,
      current: current,
      options: [for (final d in RelockDelay.values) (d, _relockLabel(l10n, d))],
    );
    // 시트가 열린 사이 일기가 잠겼으면 고른 값을 버린다.
    if (picked == null || lock.state is! LockUnlocked) return;
    await settings.setRelockDelay(picked);
    lock.configChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // 잠긴 동안 PIN 없이 다시 잠기는 시간을 바꾸지 못한다. 잠금 행은 스스로 비밀을 확인하므로
    // 그대로 둔다.
    final diaryUnlocked = context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    );
    final lock = context.select<DiarySettingsCubit, LockConfig?>(
      (c) => c.state.lock,
    );
    final relockEnabled = lock != null && lock.enabled && diaryUnlocked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListTile(
          key: const Key('settings-diary-lock'),
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.walkDiarySettingsLock),
          trailing: lock == null ? null : Text(_lockLabel(l10n, lock)),
          onTap: () => _openLockSetup(context),
        ),
        AppListTile(
          key: const Key('settings-diary-relock'),
          leading: const Icon(Icons.timer_outlined),
          title: Text(l10n.walkDiarySettingsRelock),
          trailing: lock == null
              ? null
              : Text(_relockLabel(l10n, lock.relockDelay)),
          // 잠금이 꺼져 있으면 다시 잠길 일이 없다.
          enabled: relockEnabled,
          onTap: relockEnabled
              ? () => _pickRelock(context, lock.relockDelay)
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(
            l10n.walkAppSettingsLockDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  static String _lockLabel(AppLocalizations l10n, LockConfig lock) {
    if (!lock.enabled) return l10n.walkDiarySettingsLockOff;
    return switch (lock.method) {
      LockMethod.pin => l10n.walkLockSetupPin,
      LockMethod.pattern => l10n.walkLockSetupPattern,
    };
  }

  static String _relockLabel(AppLocalizations l10n, RelockDelay delay) =>
      switch (delay) {
        RelockDelay.immediate => l10n.walkDiarySettingsRelockImmediate,
        RelockDelay.seconds30 => l10n.walkDiarySettingsRelock30s,
        RelockDelay.minute1 => l10n.walkDiarySettingsRelock1m,
        RelockDelay.minutes5 => l10n.walkDiarySettingsRelock5m,
      };
}
