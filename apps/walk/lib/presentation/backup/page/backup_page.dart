import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/backup/restore_notice.dart';
import '../../common/format_bytes.dart';
import '../../common/status_label.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../cubit/backup_cubit.dart';
import '../cubit/backup_state.dart';
import '../widget/backup_area_labels.dart';
import '../widget/backup_password_dialog.dart';
import '../widget/export_sheet.dart';
import '../widget/restore_areas_sheet.dart';

/// 설정 → 백업(스펙 §8). 백업 파일 만들기 · 백업에서 복원 · 복원 전으로 되돌리기.
///
/// 잠금 밖 화면이지만 일기가 잠겨 있으면([LockUnlocked] 아님) 행을 막는다 — 잠금을 우회해
/// 데이터를 빼내거나 바꿀 수 없게. 시트 · 대화상자가 열린 사이 잠기면 고른 것을 버린다.
/// 셸의 [DiaryLockCubit] 이 위에 있어야 한다.
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<BackupCubit>()..load(),
    child: const _BackupView(),
  );
}

class _BackupView extends StatelessWidget {
  const _BackupView();

  @override
  Widget build(BuildContext context) => BlocConsumer<BackupCubit, BackupState>(
    listener: _onState,
    builder: (context, state) => PopScope<Object?>(
      canPop: state is! BackupWorking,
      child: Stack(
        children: [
          const _BackupScaffold(),
          if (state case BackupWorking(:final step, :final progress))
            Positioned.fill(
              child: _Progress(step: step, progress: progress),
            ),
        ],
      ),
    ),
  );

  /// 지나가는 상태마다 알림 · 대화상자를 띄우고 cubit 을 다음으로 넘긴다.
  static Future<void> _onState(BuildContext context, BackupState state) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BackupCubit>();
    final lock = context.read<DiaryLockCubit>();
    bool locked() => lock.state is! LockUnlocked;
    switch (state) {
      case BackupExported(:final bytes):
        AppSnackBar.show(
          context,
          message: l10n.walkBackupExported(formatBytes(bytes)),
          type: AppSnackBarType.success,
        );
      case BackupFailed(:final failure, needsRestart: false):
        AppSnackBar.show(
          context,
          message: l10n.backupFailure(failure),
          type: AppSnackBarType.error,
        );
      case BackupFailed(needsRestart: true):
        await _RestartDialog.show(
          context,
          title: l10n.walkBackupRecoveryTitle,
          lines: [l10n.walkBackupRecoveryBody],
        );
        if (context.mounted) await _restart(context, cubit);
      case BackupPasswordNeeded(:final wrong):
        final password = await BackupPasswordDialog.show(context, wrong: wrong);
        if (password == null || locked()) {
          await cubit.cancelOpen();
        } else {
          await cubit.submitPassword(password);
        }
      case BackupInspected(:final backup):
        final areas = await RestoreAreasSheet.show(context, backup: backup);
        if (areas == null || locked() || !context.mounted) {
          await cubit.discard();
          return;
        }
        final confirmed = await AppConfirmDialog.show(
          context,
          title: l10n.walkBackupRestoreConfirmTitle,
          content: l10n.walkBackupRestoreConfirmBody(
            backupCreatedLabel(l10n, backup.manifest.createdAt),
          ),
          confirmLabel: l10n.walkBackupRestoreAction,
        );
        if (!confirmed || locked()) {
          await cubit.discard();
        } else {
          await cubit.restore(areas);
        }
      case BackupRestored(:final notices):
        await _RestartDialog.show(
          context,
          title: l10n.walkBackupResultTitle,
          lines: [
            for (final notice in RestoreNotice.values)
              if (notices.contains(notice)) l10n.restoreNotice(notice),
            l10n.walkBackupResultRestart,
          ],
        );
        if (context.mounted) await _restart(context, cubit);
      case BackupIdle() || BackupWorking():
        break;
    }
  }

  static Future<void> _restart(BuildContext context, BackupCubit cubit) async {
    try {
      await cubit.restartApp();
    } on Object {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: AppLocalizations.of(context).walkBackupFailIo,
        type: AppSnackBarType.error,
      );
    }
  }
}

/// 행 · 안내. idle 일 때만 다시 그린다(진행 중에도 뒤에 마지막 모습이 남는다).
class _BackupScaffold extends StatelessWidget {
  const _BackupScaffold();

  Future<void> _export(BuildContext context) async {
    final cubit = context.read<BackupCubit>();
    final lock = context.read<DiaryLockCubit>();
    final request = await ExportSheet.show(context, previews: cubit.preview());
    if (request == null || lock.state is! LockUnlocked) return;
    await cubit.export(request.areas, password: request.password);
  }

  Future<void> _undo(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BackupCubit>();
    final lock = context.read<DiaryLockCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkBackupUndoConfirmTitle,
      content: l10n.walkBackupUndoConfirmBody,
      confirmLabel: l10n.walkBackupUndoConfirmAction,
    );
    if (!confirmed || lock.state is! LockUnlocked) return;
    await cubit.undo();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkBackupSettingsTitle)),
      body: BlocBuilder<BackupCubit, BackupState>(
        buildWhen: (_, next) => next is BackupIdle,
        builder: (context, state) {
          final idle = state is BackupIdle ? state : const BackupIdle();
          return ListView(
            children: [
              if (!unlocked)
                AppBanner(
                  key: const Key('backup-locked'),
                  tone: AppBannerTone.warning,
                  icon: Icons.lock_outline,
                  message: l10n.walkBackupSettingsLocked,
                ),
              AppListTile(
                key: const Key('backup-create'),
                leading: const Icon(Icons.upload_outlined),
                title: Text(l10n.walkBackupSettingsCreate),
                subtitle: _LastBackup(idle: idle),
                enabled: unlocked,
                onTap: unlocked ? () => _export(context) : null,
              ),
              AppListTile(
                key: const Key('backup-restore'),
                leading: const Icon(Icons.download_outlined),
                title: Text(l10n.walkBackupSettingsRestore),
                enabled: unlocked,
                onTap: unlocked
                    ? () => context.read<BackupCubit>().openBackup()
                    : null,
              ),
              if (idle.hasUndo)
                AppListTile(
                  key: const Key('backup-undo'),
                  leading: const Icon(Icons.restore_outlined),
                  title: Text(l10n.walkBackupSettingsUndo),
                  enabled: unlocked,
                  onTap: unlocked ? () => _undo(context) : null,
                ),
              AppFootnote(
                l10n.walkBackupSettingsExcluded,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
              ),
              AppFootnote(l10n.walkBackupSettingsCloudNote),
            ],
          );
        },
      ),
    );
  }
}

/// "마지막 백업: 3일 전" · 30일이 넘으면 "오래됨"(알림 없음).
class _LastBackup extends StatelessWidget {
  const _LastBackup({required this.idle});

  final BackupIdle idle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = idle.daysAgo;
    if (days == null) return Text(l10n.walkBackupSettingsNever);
    final last = Text(l10n.walkBackupSettingsLastAt(days));
    if (!idle.stale) return last;
    return Wrap(
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        last,
        StatusLabel(l10n.walkBackupSettingsStale, tone: StatusTone.attention),
      ],
    );
  }
}

/// 전체 화면 진행 표시 — 다른 조작을 막는다. 비율을 아는 단계면 퍼센트를 함께 보인다.
class _Progress extends StatelessWidget {
  const _Progress({required this.step, this.progress});

  final BackupStep step;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        ModalBarrier(dismissible: false, color: theme.colorScheme.surface),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoading(),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocalizations.of(context).backupStep(step),
                style: theme.textTheme.bodyLarge,
              ),
              if (progress case final p?)
                Text(
                  NumberFormat.percentPattern(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(p),
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 다시 시작만 할 수 있는 안내(복원 결과 · 복구 필요). 바깥 · 뒤로로 닫지 않는다.
/// AppConfirmDialog 는 취소 버튼이 늘 있어 쓸 수 없다.
class _RestartDialog extends StatelessWidget {
  const _RestartDialog({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<String> lines,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RestartDialog(title: title, lines: lines),
  );

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    child: AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(line),
            ),
        ],
      ),
      actions: [
        AppButton.primary(
          compact: true,
          label: AppLocalizations.of(context).walkBackupRestartAction,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
