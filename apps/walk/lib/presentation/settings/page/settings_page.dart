import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:permission/permission.dart';

import '../../../domain/settings/entity/app_settings.dart';
import '../../../domain/walk/entity/health_access.dart';
import '../../walk/cubit/step_goal_cubit.dart';
import '../../walk/format/walk_format.dart';
import '../cubit/settings_permissions_cubit.dart';
import '../cubit/settings_permissions_state.dart';
import '../cubit/theme_cubit.dart';
import '../widget/step_goal_sheet.dart';

/// 설정 탭 — 걷기(하루 목표) · 권한 모아보기 · 테마.
/// [SettingsPermissionsCubit] 은 셸이, [ThemeCubit] · [StepGoalCubit] 은 앱이 제공한다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissions = context.read<SettingsPermissionsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkSettingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l10n.walkSettingsWalk),
          BlocBuilder<StepGoalCubit, int>(
            builder: (context, goal) => AppListTile(
              key: const Key('settings-step-goal'),
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.walkSettingsStepGoal),
              trailing: Text(
                l10n.walkStepsCount(WalkFormat.steps(l10n.localeName, goal)),
              ),
              onTap: () async {
                final cubit = context.read<StepGoalCubit>();
                final result = await StepGoalSheet.show(context, initial: goal);
                if (result != null) await cubit.select(result);
              },
            ),
          ),
          _SectionHeader(l10n.walkSettingsPermissions),
          BlocBuilder<SettingsPermissionsCubit, SettingsPermissionsState>(
            builder: (context, state) => Column(
              children: [
                _PermissionTile(
                  title: l10n.walkSettingsNotification,
                  description: l10n.walkSettingsNotificationDescription,
                  status: _statusLabel(l10n, state.notification),
                  onTap: permissions.openNotification,
                ),
                _PermissionTile(
                  title: l10n.walkSettingsExactAlarm,
                  description: l10n.walkSettingsExactAlarmDescription,
                  status: _statusLabel(l10n, state.exactAlarm),
                  onTap: permissions.openExactAlarm,
                ),
                _PermissionTile(
                  title: l10n.walkSettingsFullScreen,
                  description: l10n.walkSettingsFullScreenDescription,
                  status: _statusLabel(l10n, state.fullScreenIntent),
                  onTap: permissions.openFullScreenIntent,
                ),
                _PermissionTile(
                  title: l10n.walkSettingsHealthConnect,
                  description: l10n.walkSettingsHealthConnectDescription,
                  status: _healthLabel(l10n, state.health),
                  onTap: permissions.openHealth,
                ),
              ],
            ),
          ),
          _SectionHeader(l10n.walkSettingsTheme),
          BlocBuilder<ThemeCubit, AppThemeMode>(
            builder: (context, mode) => RadioGroup<AppThemeMode>(
              groupValue: mode,
              onChanged: (value) {
                if (value != null) context.read<ThemeCubit>().select(value);
              },
              // 라디오 행은 AppListTile 로 그릴 수 없다(선택 표시 · 접근성 역할이 라디오).
              child: Column(
                children: [
                  for (final (value, label) in [
                    (AppThemeMode.system, l10n.walkSettingsThemeSystem),
                    (AppThemeMode.light, l10n.walkSettingsThemeLight),
                    (AppThemeMode.dark, l10n.walkSettingsThemeDark),
                  ])
                    RadioListTile<AppThemeMode>(
                      value: value,
                      title: Text(label),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static _Status? _statusLabel(
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

  static _Status? _healthLabel(AppLocalizations l10n, HealthAccess? access) =>
      switch (access) {
        null => null,
        HealthAccess.granted => (l10n.walkSettingsGranted, false),
        HealthAccess.permissionDenied => (
          l10n.walkSettingsNeedsPermission,
          true,
        ),
        HealthAccess.notInstalled => (l10n.walkSettingsNeedsInstall, true),
        HealthAccess.updateRequired => (l10n.walkSettingsNeedsUpdate, true),
      };
}

/// (표시 문구, 조치가 필요한가)
typedef _Status = (String, bool);

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

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

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.description,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String description;

  /// null = 확인 중.
  final _Status? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = this.status;
    return AppListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: status == null
          ? null
          : Text(
              status.$1,
              style: TextStyle(
                color: status.$2 ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
      onTap: onTap,
    );
  }
}
