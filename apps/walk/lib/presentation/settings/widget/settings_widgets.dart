import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:permission/permission.dart';

import '../../../domain/walk/entity/health_access.dart';
import '../../common/status_label.dart';

// 설정 화면들이 함께 쓰는 조각 — 권한 행, 보기 고르기 시트.

/// (표시 문구, 조치가 필요한가)
typedef SettingsStatus = (String, bool);

/// 시스템 권한 상태 문구. null = 확인 중.
SettingsStatus? settingsStatusLabel(
  AppLocalizations l10n,
  PermissionStatus? status,
) => switch (status) {
  null => null,
  PermissionStatus.granted => (l10n.walkSettingsGranted, false),
  PermissionStatus.denied || PermissionStatus.permanentlyDenied => (
    l10n.walkSettingsNeedsPermission,
    true,
  ),
};

/// Health Connect 상태 문구. null = 확인 중.
SettingsStatus? settingsHealthLabel(
  AppLocalizations l10n,
  HealthAccess? access,
) => switch (access) {
  null => null,
  HealthAccess.granted => (l10n.walkSettingsGranted, false),
  HealthAccess.permissionDenied => (l10n.walkSettingsNeedsPermission, true),
  HealthAccess.notInstalled => (l10n.walkSettingsNeedsInstall, true),
  HealthAccess.updateRequired => (l10n.walkSettingsNeedsUpdate, true),
};

/// 권한 한 줄 — 제목 · 설명 · 오른쪽 상태(조치가 필요하면 오류색).
class SettingsPermissionTile extends StatelessWidget {
  const SettingsPermissionTile({
    required this.title,
    required this.description,
    required this.status,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;

  /// null = 확인 중.
  final SettingsStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return AppListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: status == null
          ? null
          : StatusLabel(
              status.$1,
              tone: status.$2 ? StatusTone.attention : StatusTone.neutral,
            ),
      onTap: onTap,
    );
  }
}

/// 보기 중 하나를 고르는 바텀시트. 고른 값을, 닫으면 null 을 돌려준다.
class SettingsChoiceSheet<T> extends StatelessWidget {
  const SettingsChoiceSheet({
    required this.title,
    required this.current,
    required this.options,
    super.key,
  });

  final String title;
  final T current;
  final List<(T, String)> options;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required T current,
    required List<(T, String)> options,
  }) => showAppSheet<T>(
    context: context,
    builder: (_) => SettingsChoiceSheet<T>(
      title: title,
      current: current,
      options: options,
    ),
  );

  @override
  Widget build(BuildContext context) => AppSheetScaffold(
    title: title,
    children: [
      for (final (value, label) in options)
        AppSelectTile(
          title: Text(label),
          selected: value == current,
          onTap: () => Navigator.pop(context, value),
        ),
    ],
  );
}
