import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:permission/permission.dart';

import '../../../domain/alarm/holiday/holiday_calendar.dart';
import '../../../domain/settings/entity/app_settings.dart';
import '../../../domain/walk/entity/health_access.dart';
import '../../walk/cubit/step_goal_cubit.dart';
import '../../walk/format/walk_format.dart';
import '../cubit/holiday_settings_cubit.dart';
import '../cubit/holiday_settings_state.dart';
import '../cubit/settings_permissions_cubit.dart';
import '../cubit/settings_permissions_state.dart';
import '../cubit/theme_cubit.dart';
import '../widget/step_goal_sheet.dart';

/// 설정 탭 — 걷기(하루 목표) · 알람(공휴일 미리 알림 · 공휴일 출처) · 권한 모아보기 · 테마.
/// [SettingsPermissionsCubit] · [HolidaySettingsCubit] 은 셸이, [ThemeCubit] · [StepGoalCubit] 은
/// 앱이 제공한다.
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
          _SectionHeader(l10n.walkSettingsAlarm),
          BlocBuilder<HolidaySettingsCubit, HolidaySettingsState>(
            builder: (context, state) {
              final cubit = context.read<HolidaySettingsCubit>();
              final scheme = Theme.of(context).colorScheme;
              final source = state.source;
              final calendar = state.calendar;
              return Column(
                children: [
                  AppListTile(
                    key: const Key('settings-holiday-reminder'),
                    leading: const Icon(Icons.event_outlined),
                    title: Text(l10n.walkSettingsHolidayReminder),
                    subtitle: Text(l10n.walkSettingsHolidayReminderDescription),
                    trailing: Switch(
                      value: state.holidayReminder,
                      onChanged: cubit.setHolidayReminder,
                    ),
                    onTap: () => cubit.setHolidayReminder(!state.holidayReminder),
                  ),
                  AppListTile(
                    key: const Key('settings-holiday-source'),
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(l10n.walkSettingsHolidaySource),
                    subtitle: source == null ? null : Text(_sourceLabel(l10n, source)),
                    trailing: calendar == null
                        ? null
                        : Text(
                            calendar == PermissionStatus.granted
                                ? l10n.walkSettingsCalendarGranted
                                : l10n.walkSettingsCalendarNeedsPermission,
                            style: TextStyle(
                              color: calendar == PermissionStatus.granted
                                  ? scheme.onSurfaceVariant
                                  : scheme.error,
                            ),
                          ),
                    onTap: cubit.openCalendar,
                  ),
                ],
              );
            },
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

  /// "폰 캘린더: 대한민국의 휴일" · "내장 표 2026–2027".
  static String _sourceLabel(AppLocalizations l10n, HolidaySource source) => switch (source) {
    DeviceCalendarHolidays(calendarName: '') => l10n.walkSettingsHolidaySourceDeviceUnnamed,
    DeviceCalendarHolidays(:final calendarName) => l10n.walkSettingsHolidaySourceDevice(calendarName),
    BundledHolidays(:final firstYear, :final lastYear) =>
      l10n.walkSettingsHolidaySourceBundled('$firstYear', '$lastYear'),
  };

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
