import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_service.dart';
import 'backup_area_labels.dart';
import 'backup_password_dialog.dart';

/// 내보내기 시트의 결과 — 담을 영역과 비밀번호(암호화를 껐으면 null).
typedef ExportRequest = ({Set<BackupAreaId> areas, String? password});

/// 내보내기 시트(스펙 §8) — 담을 영역(위치 기록만 처음에 끔) · 비밀번호로 잠그기(처음에 켬).
///
/// 저장 버튼은 영역이 하나 이상이고, 잠그기를 켰으면 비밀번호가 8자 이상 · 두 번 같고 ·
/// "잊으면 복원할 수 없어요"를 체크했을 때만 켜진다.
class ExportSheet extends StatefulWidget {
  const ExportSheet({required this.previews, super.key});

  /// 영역별 지금 개수 · 크기. 오는 대로 부제에 채운다.
  final Future<Map<BackupAreaId, AreaPreview>> previews;

  static Future<ExportRequest?> show(
    BuildContext context, {
    required Future<Map<BackupAreaId, AreaPreview>> previews,
  }) => showModalBottomSheet<ExportRequest>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ExportSheet(previews: previews),
  );

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  final _areas = {
    for (final id in BackupAreaId.values)
      if (id.defaultSelected) id,
  };
  final _password = TextEditingController();
  final _again = TextEditingController();
  bool _encrypt = true;
  bool _forgetAck = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_rebuild);
    _again.addListener(_rebuild);
  }

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  bool get _passwordReady =>
      _password.text.length >= BackupPasswordDialog.minLength &&
      _password.text == _again.text &&
      _forgetAck;

  bool get _canSave => _areas.isNotEmpty && (!_encrypt || _passwordReady);

  void _save() => Navigator.of(context).pop<ExportRequest>((
    areas: {..._areas},
    password: _encrypt ? _password.text : null,
  ));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final note = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  l10n.walkBackupSheetTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FutureBuilder<Map<BackupAreaId, AreaPreview>>(
                future: widget.previews,
                builder: (context, snapshot) {
                  final previews = snapshot.data ?? const {};
                  return Column(
                    children: [
                      // 체크 행은 AppListTile 로 그릴 수 없다(선택 표시 · 접근성 역할이 체크박스).
                      for (final id in BackupAreaId.values)
                        CheckboxListTile(
                          key: Key('backup-export-area-${id.name}'),
                          value: _areas.contains(id),
                          title: Text(l10n.backupAreaName(id)),
                          subtitle: switch (previews[id]) {
                            final p? => switch (l10n.backupAreaCounts(
                              id,
                              p.counts,
                              bytes: p.bytes,
                            )) {
                              final text? => Text(text),
                              null => null,
                            },
                            null => null,
                          },
                          onChanged: (on) => setState(
                            () =>
                                on == true ? _areas.add(id) : _areas.remove(id),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Divider(),
              SwitchListTile(
                key: const Key('backup-export-encrypt'),
                value: _encrypt,
                title: Text(l10n.walkBackupSheetEncrypt),
                onChanged: (on) => setState(() => _encrypt = on),
              ),
              if (_encrypt) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      BackupPasswordField(
                        key: const Key('backup-export-password'),
                        controller: _password,
                        label: l10n.walkBackupSheetPassword,
                        helperText: l10n.walkBackupSheetPasswordHint,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      BackupPasswordField(
                        key: const Key('backup-export-password-again'),
                        controller: _again,
                        label: l10n.walkBackupSheetPasswordAgain,
                        errorText:
                            _again.text.isNotEmpty &&
                                _again.text != _password.text
                            ? l10n.walkBackupSheetPasswordMismatch
                            : null,
                      ),
                    ],
                  ),
                ),
                CheckboxListTile(
                  key: const Key('backup-export-forget-ack'),
                  value: _forgetAck,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.walkBackupSheetForgetAck),
                  onChanged: (on) => setState(() => _forgetAck = on == true),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(l10n.walkBackupSheetUnencrypted, style: note),
                ),
                if (_areas.contains(BackupAreaId.location))
                  Padding(
                    key: const Key('backup-export-location-warning'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      0,
                    ),
                    child: Text(
                      l10n.walkBackupSheetLocationUnencrypted,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton.primary(
                  key: const Key('backup-export-save'),
                  label: l10n.walkBackupSheetSave,
                  onPressed: _canSave ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
