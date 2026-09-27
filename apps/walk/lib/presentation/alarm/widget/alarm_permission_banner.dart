import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 알림 · 정확한 알람 중 하나라도 거부됐을 때 목록 위 경고. 누르면 설정 탭으로 간다.
class AlarmPermissionBanner extends StatelessWidget {
  const AlarmPermissionBanner({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: AppRadius.smAll,
      clipBehavior: Clip.antiAlias,
      child: ListTileTheme.merge(
        textColor: scheme.onErrorContainer,
        iconColor: scheme.onErrorContainer,
        child: AppListTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text(l10n.walkAlarmPermissionWarning),
          subtitle: Text(l10n.walkAlarmPermissionWarningAction),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
