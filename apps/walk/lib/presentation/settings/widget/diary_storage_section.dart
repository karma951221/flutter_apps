import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_usage.dart';
import '../../../domain/diary/entity/trash_retention.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../cubit/diary_settings_cubit.dart';
import '../cubit/diary_settings_state.dart';
import 'settings_widgets.dart';

/// 일기 보관 — 휴지통 보관 기간 · 저장 공간 · "이 폰에만 저장" 안내.
///
/// [DiarySettingsCubit] 와 [DiaryLockCubit] 은 셸이 제공하고, 읽기([DiarySettingsCubit.load])는
/// 이 섹션을 담은 화면이 한다.
class DiaryStorageSection extends StatelessWidget {
  const DiaryStorageSection({super.key});

  Future<void> _pickRetention(
    BuildContext context,
    TrashRetention current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<DiarySettingsCubit>();
    final lock = context.read<DiaryLockCubit>();
    final picked = await SettingsChoiceSheet.show<TrashRetention>(
      context,
      title: l10n.walkDiarySettingsRetention,
      current: current,
      options: [
        for (final r in TrashRetention.values) (r, _retentionLabel(l10n, r)),
      ],
    );
    // 시트가 열린 사이 일기가 잠겼으면 고른 값을 버린다.
    if (picked == null || lock.state is! LockUnlocked) return;
    await settings.setRetention(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // 일기가 잠긴 동안 PIN 없이 휴지통 기한을 바꾸지 못한다(보관 기간을 줄이면 다음 정리에서
    // 영구 삭제된다).
    final diaryUnlocked = context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    );
    return BlocBuilder<DiarySettingsCubit, DiarySettingsState>(
      builder: (context, state) {
        final usage = state.usage;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListTile(
              key: const Key('settings-diary-retention'),
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.walkDiarySettingsRetention),
              trailing: Text(_retentionLabel(l10n, state.retention)),
              enabled: diaryUnlocked,
              onTap: diaryUnlocked
                  ? () => _pickRetention(context, state.retention)
                  : null,
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

  static String _retentionLabel(AppLocalizations l10n, TrashRetention r) =>
      switch (r) {
        TrashRetention.day1 => l10n.walkDiarySettingsRetention1d,
        TrashRetention.day7 => l10n.walkDiarySettingsRetention7d,
        TrashRetention.day30 => l10n.walkDiarySettingsRetention30d,
        TrashRetention.never => l10n.walkDiarySettingsRetentionNever,
      };
}
