import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../walk/cubit/step_goal_cubit.dart';
import '../cubit/diary_settings_cubit.dart';
import '../cubit/holiday_settings_cubit.dart';
import '../cubit/settings_permissions_cubit.dart';
import '../cubit/theme_cubit.dart';
import '../widget/chat_settings_section.dart';
import '../widget/diary_storage_section.dart';
import '../widget/lock_settings_section.dart';
import '../widget/settings_widgets.dart';
import 'alarm_settings_page.dart';
import 'app_settings_page.dart';
import 'walk_settings_page.dart';

/// 설정 탭 — 걷기(하루 목표) · 알람(공휴일 미리 알림 · 공휴일 출처) · 일기(잠금 · 휴지통 ·
/// 저장 공간) · 권한 모아보기 · 테마. 기능별 설정 화면의 조각을 모아 그린다.
/// [SettingsPermissionsCubit] · [HolidaySettingsCubit] · [DiarySettingsCubit] · `DiaryLockCubit` 은
/// 셸이, [ThemeCubit] · [StepGoalCubit] 은 앱이 제공한다.
class SettingsPage extends StatefulWidget {
  const SettingsPage({this.active = true, super.key});

  /// 설정 탭이 지금 보이는가. 다시 보일 때 일기 저장 공간을 다시 읽는다.
  final bool active;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DiarySettingsCubit>().load();
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      context.read<DiarySettingsCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkSettingsTitle)),
      body: ListView(
        children: [
          SettingsSectionHeader(l10n.walkSettingsWalk),
          const StepGoalTile(),
          SettingsSectionHeader(l10n.walkSettingsAlarm),
          const HolidaySettingsTiles(),
          SettingsSectionHeader(l10n.walkDiarySettings),
          const LockSettingsSection(),
          const DiaryStorageSection(),
          const ChatSettingsSection(),
          SettingsSectionHeader(l10n.walkSettingsPermissions),
          const AlarmPermissionTiles(),
          const HealthPermissionTile(),
          SettingsSectionHeader(l10n.walkSettingsTheme),
          const ThemeSettingsRadios(),
        ],
      ),
    );
  }
}
