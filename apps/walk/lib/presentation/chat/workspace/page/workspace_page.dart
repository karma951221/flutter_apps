import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/attachment/attachment_rules.dart';
import '../../../../domain/chat/workspace/workspace.dart';
import '../../../settings/widget/diary_storage_section.dart';
import '../../../settings/widget/settings_widgets.dart';
import '../../widget/attachment_chip.dart';
import '../cubit/workspace_cubit.dart';
import '../cubit/workspace_state.dart';
import '../open_workspace.dart';

enum _RowAction { attach, share, delete }

/// 작업 폴더 — 맨 위 전체 사용량, 아래 "저장한 결과(out)" · "첨부한 파일(inbox)" 두 구역(각 최신순).
/// 행을 누르면 보기(`openWorkspaceFile`), 행 ⋮ 는 [물어보기에 첨부] · [공유] · [지우기].
/// [물어보기에 첨부]는 그 파일로 pop 한다 — `openWorkspace` 로 연다(잠금 아래).
class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => WorkspaceCubit(getIt<Workspace>())..load(),
    child: Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).walkWorkspaceTitle),
      ),
      body: BlocBuilder<WorkspaceCubit, WorkspaceState>(
        builder: (context, state) => _body(context, state),
      ),
    ),
  );

  Widget _body(BuildContext context, WorkspaceState state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return switch (state) {
      WorkspaceLoading() => const Center(child: CircularProgressIndicator()),
      WorkspaceFailure() => AppPlaceholder(
        icon: Icons.error_outline,
        message: l10n.walkWorkspaceLoadFailed,
      ),
      WorkspaceReady(totalCount: 0) => AppPlaceholder(
        icon: Icons.folder_open_outlined,
        message: l10n.walkWorkspaceEmpty,
        description: l10n.walkWorkspaceEmptyHint,
      ),
      WorkspaceReady(
        :final out,
        :final inbox,
        :final totalCount,
        :final totalBytes,
      ) =>
        ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Text(
                l10n.walkWorkspaceUsage(
                  totalCount,
                  DiaryStorageSection.formatBytes(totalBytes),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (out.isNotEmpty) ...[
              SettingsSectionHeader(l10n.walkWorkspaceOutSection),
              for (final f in out) _FileRow(file: f),
            ],
            if (inbox.isNotEmpty) ...[
              SettingsSectionHeader(l10n.walkWorkspaceInboxSection),
              for (final f in inbox) _FileRow(file: f),
            ],
          ],
        ),
    };
  }
}

/// 파일 한 행 — 종류 아이콘 · 이름 · `1.2MB · 11월 13일 14:05` · 행 메뉴.
class _FileRow extends StatelessWidget {
  const _FileRow({required this.file});

  final WorkspaceFile file;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind = AttachmentRules.kindOf(file.name);
    return AppListTile(
      key: Key('workspace-file-${file.path}'),
      leading: Icon(
        kind == null
            ? Icons.insert_drive_file_outlined
            : AttachmentChip.iconOf(kind),
      ),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(_detail(file, l10n.localeName)),
      trailing: AppOverflowMenu<_RowAction>(
        items: [
          AppOverflowMenuItem(
            value: _RowAction.attach,
            label: l10n.walkWorkspaceAttach,
            icon: Icons.attach_file,
          ),
          AppOverflowMenuItem(
            value: _RowAction.share,
            label: l10n.walkWorkspaceShare,
            icon: Icons.share_outlined,
          ),
          AppOverflowMenuItem(
            value: _RowAction.delete,
            label: l10n.walkWorkspaceDelete,
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
        ],
        onSelected: (action) => switch (action) {
          _RowAction.attach => Navigator.of(context).pop(file),
          _RowAction.share => unawaited(
            shareWorkspaceFile(context, file.path, file.name),
          ),
          _RowAction.delete => unawaited(_delete(context)),
        },
      ),
      onTap: () => unawaited(openWorkspaceFile(context, file.path)),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WorkspaceCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkWorkspaceDeleteTitle,
      content: l10n.walkWorkspaceDeleteBody(file.name),
      confirmLabel: l10n.walkWorkspaceDelete,
    );
    if (!confirmed) return;
    final ok = await cubit.delete(file);
    if (!ok && context.mounted) {
      AppSnackBar.show(
        context,
        message: l10n.walkWorkspaceDeleteFailed,
        type: AppSnackBarType.error,
      );
    }
  }
}

/// 행 부제 — `1.2MB · 11월 13일 14:05`.
String _detail(WorkspaceFile file, String locale) =>
    '${DiaryStorageSection.formatBytes(file.sizeBytes)} · '
    '${DateFormat.MMMd(locale).add_Hm().format(file.modifiedAt)}';
