import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_usage.dart';
import '../../../domain/diary/entity/trash_retention.dart';
import '../../../domain/lock/lock_config.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/page/lock_setup_page.dart';
import '../cubit/diary_settings_cubit.dart';
import '../cubit/diary_settings_state.dart';

/// 설정 탭 "일기" 섹션(스펙 §8) — 잠금 · 다시 잠기는 시간 · 휴지통 보관 기간 · 저장 공간 · 안내.
///
/// [DiarySettingsCubit] 와 [DiaryLockCubit] 은 셸이 제공한다. 처음 그려질 때와 [active] 가
/// 거짓에서 참으로 바뀔 때(설정 탭이 다시 보일 때) 다시 읽는다.
class DiarySettingsSection extends StatefulWidget {
  const DiarySettingsSection({required this.active, super.key});

  final bool active;

  @override
  State<DiarySettingsSection> createState() => _DiarySettingsSectionState();
}

class _DiarySettingsSectionState extends State<DiarySettingsSection> {
  @override
  void initState() {
    super.initState();
    context.read<DiarySettingsCubit>().load();
  }

  @override
  void didUpdateWidget(DiarySettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      context.read<DiarySettingsCubit>().load();
    }
  }

  /// 잠금 설정 화면은 일기 화면이 아니다 — 스스로 현재 비밀을 확인하므로 그냥 push 한다.
  /// 바뀌었으면(`true`) 일기 잠금에 알리고 이 섹션을 다시 읽는다.
  Future<void> _openLockSetup() async {
    final settings = context.read<DiarySettingsCubit>();
    final lock = context.read<DiaryLockCubit>();
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LockSetupPage()));
    if (changed != true) return;
    lock.configChanged();
    await settings.load();
  }

  Future<void> _pickRelock(RelockDelay current) async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<DiarySettingsCubit>();
    final lock = context.read<DiaryLockCubit>();
    final picked = await _ChoiceSheet.show<RelockDelay>(
      context,
      title: l10n.walkDiarySettingsRelock,
      current: current,
      options: [for (final d in RelockDelay.values) (d, _relockLabel(l10n, d))],
    );
    if (picked == null) return;
    await settings.setRelockDelay(picked);
    lock.configChanged();
  }

  Future<void> _pickRetention(TrashRetention current) async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<DiarySettingsCubit>();
    final picked = await _ChoiceSheet.show<TrashRetention>(
      context,
      title: l10n.walkDiarySettingsRetention,
      current: current,
      options: [
        for (final r in TrashRetention.values) (r, _retentionLabel(l10n, r)),
      ],
    );
    if (picked != null) await settings.setRetention(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocBuilder<DiarySettingsCubit, DiarySettingsState>(
      builder: (context, state) {
        final lock = state.lock;
        final usage = state.usage;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(l10n.walkDiarySettings),
            AppListTile(
              key: const Key('settings-diary-lock'),
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.walkDiarySettingsLock),
              trailing: lock == null ? null : Text(_lockLabel(l10n, lock)),
              onTap: _openLockSetup,
            ),
            AppListTile(
              key: const Key('settings-diary-relock'),
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.walkDiarySettingsRelock),
              trailing: lock == null
                  ? null
                  : Text(_relockLabel(l10n, lock.relockDelay)),
              // 잠금이 꺼져 있으면 다시 잠길 일이 없다.
              enabled: lock != null && lock.enabled,
              onTap: lock == null || !lock.enabled
                  ? null
                  : () => _pickRelock(lock.relockDelay),
            ),
            AppListTile(
              key: const Key('settings-diary-retention'),
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.walkDiarySettingsRetention),
              trailing: Text(_retentionLabel(l10n, state.retention)),
              onTap: () => _pickRetention(state.retention),
            ),
            AppListTile(
              key: const Key('settings-diary-storage'),
              leading: const Icon(Icons.storage_outlined),
              title: Text(l10n.walkDiarySettingsStorage),
              subtitle: usage == null ? null : _usageText(l10n, usage),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.walkDiarySettingsLocalOnly,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _usageText(AppLocalizations l10n, DiaryUsage usage) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.walkDiarySettingsStorageUsage(formatBytes(usage.bytes))),
      Text(
        l10n.walkDiarySettingsStorageDetail(
          usage.photos,
          usage.videos,
          formatBytes(usage.trashBytes),
        ),
      ),
    ],
  );

  /// 1024 단위. B · KB 는 정수, MB 부터 소수점 한 자리("1.2GB").
  static String formatBytes(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)}GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)}MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)}KB';
    return '${bytes}B';
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

  static String _retentionLabel(AppLocalizations l10n, TrashRetention r) =>
      switch (r) {
        TrashRetention.day1 => l10n.walkDiarySettingsRetention1d,
        TrashRetention.day7 => l10n.walkDiarySettingsRetention7d,
        TrashRetention.day30 => l10n.walkDiarySettingsRetention30d,
        TrashRetention.never => l10n.walkDiarySettingsRetentionNever,
      };
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// 보기 중 하나를 고르는 바텀시트. 고른 값을, 닫으면 null 을 돌려준다.
class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.current,
    required this.options,
  });

  final String title;
  final T current;
  final List<(T, String)> options;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required T current,
    required List<(T, String)> options,
  }) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        _ChoiceSheet<T>(title: title, current: current, options: options),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          for (final (value, label) in options)
            AppListTile(
              title: Text(label),
              trailing: value == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(context, value),
            ),
        ],
      ),
    );
  }
}
