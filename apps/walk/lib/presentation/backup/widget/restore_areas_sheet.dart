import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_service.dart';
import 'backup_area_labels.dart';

/// 복원할 영역 고르기(스펙 §6-3). 백업에 든 영역만, 복원할 수 있는 것은 처음에 모두 체크.
/// 더 새 앱이 만든 영역은 회색으로 막고 업데이트를 안내한다. 고른 영역, 닫으면 null.
class RestoreAreasSheet extends StatefulWidget {
  const RestoreAreasSheet({required this.backup, super.key});

  final InspectedBackup backup;

  static Future<Set<BackupAreaId>?> show(
    BuildContext context, {
    required InspectedBackup backup,
  }) => showModalBottomSheet<Set<BackupAreaId>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => RestoreAreasSheet(backup: backup),
  );

  @override
  State<RestoreAreasSheet> createState() => _RestoreAreasSheetState();
}

/// 백업 만든 시각 — 시트 머리 · 확인 대화상자가 함께 쓴다.
String backupCreatedLabel(AppLocalizations l10n, DateTime at) =>
    DateFormat.yMMMd(l10n.localeName).add_Hm().format(at);

class _RestoreAreasSheetState extends State<RestoreAreasSheet> {
  late final Set<BackupAreaId> _selected = {
    for (final MapEntry(key: id, value: availability)
        in widget.backup.areas.entries)
      if (availability == AreaAvailability.ok) id,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final backup = widget.backup;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.walkBackupRestoreSheetTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    l10n.walkBackupRestoreSheetCreated(
                      backupCreatedLabel(l10n, backup.manifest.createdAt),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 체크 행은 AppListTile 로 그릴 수 없다(선택 표시 · 접근성 역할이 체크박스).
            for (final id in BackupAreaId.values)
              if (backup.areas[id] case final availability?)
                _areaTile(context, id, availability),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton.primary(
                key: const Key('backup-restore-areas-confirm'),
                label: l10n.walkBackupRestoreAction,
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop({..._selected}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _areaTile(
    BuildContext context,
    BackupAreaId id,
    AreaAvailability availability,
  ) {
    final l10n = AppLocalizations.of(context);
    final ok = availability == AreaAvailability.ok;
    final counts = l10n.backupAreaCounts(
      id,
      widget.backup.manifest.areas[id]?.counts ?? const {},
    );
    return CheckboxListTile(
      key: Key('backup-restore-area-${id.name}'),
      value: ok && _selected.contains(id),
      enabled: ok,
      title: Text(l10n.backupAreaName(id)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (counts != null) Text(counts),
          Text(
            ok
                ? l10n.walkBackupRestoreSheetReplaces
                : l10n.walkBackupRestoreSheetNewer,
          ),
        ],
      ),
      onChanged: ok
          ? (on) => setState(
              () => on == true ? _selected.add(id) : _selected.remove(id),
            )
          : null,
    );
  }
}
