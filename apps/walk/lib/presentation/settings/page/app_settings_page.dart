import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/settings/entity/app_settings.dart';
import '../cubit/diary_settings_cubit.dart';
import '../cubit/theme_cubit.dart';
import '../open_settings.dart';
import '../widget/lock_settings_section.dart';
import '../widget/settings_widgets.dart';

/// 앱 설정 — 잠금(일기 · 물어보기 함께), 화면(테마), 기능별 설정 바로가기.
///
/// 잠금 밖 화면이다. 바로가기 중 일기 · 물어보기는 잠겨 있으면 잠금 화면을 거친다
/// ([openSettings]). 열릴 때 [DiarySettingsCubit] 을 다시 읽는다(잠금 행).
class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DiarySettingsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkAppSettingsTitle)),
      body: ListView(
        children: [
          SettingsSectionHeader(l10n.walkAppSettingsLock),
          const LockSettingsSection(),
          SettingsSectionHeader(l10n.walkAppSettingsDisplay),
          const _ThemeSettingsRadios(),
          SettingsSectionHeader(l10n.walkAppSettingsFeatures),
          for (final (target, icon, title) in [
            (
              SettingsTarget.diary,
              Icons.book_outlined,
              l10n.walkDiarySettingsTitle,
            ),
            (
              SettingsTarget.chat,
              Icons.chat_bubble_outline,
              l10n.walkChatSettingsTitle,
            ),
            (
              SettingsTarget.alarm,
              Icons.alarm_outlined,
              l10n.walkAlarmSettingsTitle,
            ),
            (
              SettingsTarget.walk,
              Icons.directions_walk,
              l10n.walkWalkSettingsTitle,
            ),
          ])
            AppListTile(
              key: Key('app-settings-open-${target.name}'),
              leading: Icon(icon),
              title: Text(title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openSettings(context, target),
            ),
        ],
      ),
    );
  }
}

/// 테마 라디오 — 시스템 · 라이트 · 다크.
class _ThemeSettingsRadios extends StatelessWidget {
  const _ThemeSettingsRadios();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ThemeCubit, AppThemeMode>(
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
              RadioListTile<AppThemeMode>(value: value, title: Text(label)),
          ],
        ),
      ),
    );
  }
}
