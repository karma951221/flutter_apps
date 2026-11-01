import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:permission/permission.dart';

import '../../../domain/alarm/holiday/holiday_calendar.dart';
import '../cubit/holiday_settings_cubit.dart';
import '../cubit/holiday_settings_state.dart';
import '../cubit/settings_permissions_cubit.dart';
import '../cubit/settings_permissions_state.dart';
import '../widget/settings_widgets.dart';

/// 알람 설정 — 공휴일 미리 알림 · 공휴일 출처, 알람 권한(알림 · 정확한 알람 · 전체 화면).
///
/// [SettingsPermissionsCubit] · [HolidaySettingsCubit] 은 셸이 제공한다(`openSettings`).
/// 열릴 때 둘을 다시 읽는다.
class AlarmSettingsPage extends StatefulWidget {
  const AlarmSettingsPage({super.key});

  @override
  State<AlarmSettingsPage> createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsPermissionsCubit>().check();
    context.read<HolidaySettingsCubit>().check();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkAlarmSettingsTitle)),
      body: ListView(
        children: [
          const _HolidaySettingsTiles(),
          SettingsSectionHeader(l10n.walkSettingsPermissions),
          const _AlarmPermissionTiles(),
        ],
      ),
    );
  }
}

/// 공휴일 미리 알림 스위치 · 공휴일 출처(캘린더 권한) 행.
class _HolidaySettingsTiles extends StatelessWidget {
  const _HolidaySettingsTiles();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<HolidaySettingsCubit, HolidaySettingsState>(
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
              subtitle: source == null
                  ? null
                  : Text(_sourceLabel(l10n, source)),
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
    );
  }

  /// "폰 캘린더: 대한민국의 휴일" · "내장 표 2026–2027".
  static String _sourceLabel(AppLocalizations l10n, HolidaySource source) =>
      switch (source) {
        DeviceCalendarHolidays(calendarName: '') =>
          l10n.walkSettingsHolidaySourceDeviceUnnamed,
        DeviceCalendarHolidays(:final calendarName) =>
          l10n.walkSettingsHolidaySourceDevice(calendarName),
        BundledHolidays(:final firstYear, :final lastYear) =>
          l10n.walkSettingsHolidaySourceBundled('$firstYear', '$lastYear'),
      };
}

/// 알람이 쓰는 권한 행 — 알림 · 정확한 알람 · 전체 화면.
class _AlarmPermissionTiles extends StatelessWidget {
  const _AlarmPermissionTiles();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissions = context.read<SettingsPermissionsCubit>();
    return BlocBuilder<SettingsPermissionsCubit, SettingsPermissionsState>(
      builder: (context, state) => Column(
        children: [
          SettingsPermissionTile(
            title: l10n.walkSettingsNotification,
            description: l10n.walkSettingsNotificationDescription,
            status: settingsStatusLabel(l10n, state.notification),
            onTap: permissions.openNotification,
          ),
          SettingsPermissionTile(
            title: l10n.walkSettingsExactAlarm,
            description: l10n.walkSettingsExactAlarmDescription,
            status: settingsStatusLabel(l10n, state.exactAlarm),
            onTap: permissions.openExactAlarm,
          ),
          SettingsPermissionTile(
            title: l10n.walkSettingsFullScreen,
            description: l10n.walkSettingsFullScreenDescription,
            status: settingsStatusLabel(l10n, state.fullScreenIntent),
            onTap: permissions.openFullScreenIntent,
          ),
        ],
      ),
    );
  }
}
