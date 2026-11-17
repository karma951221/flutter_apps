import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/location/entity/record_mode.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../../../domain/settings/entity/app_settings.dart';
import '../../chat/widget/chat_vendor_icon.dart';
import '../../map/cubit/map_record_cubit.dart';
import '../../map/cubit/map_record_state.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/page/profile_page.dart';
import '../../profile/widget/profile_avatar.dart';
import '../cubit/connection_status_cubit.dart';
import '../cubit/diary_settings_cubit.dart';
import '../cubit/theme_cubit.dart';
import '../open_settings.dart';
import '../widget/lock_settings_section.dart';
import '../widget/settings_widgets.dart';

/// 하단 넷째 탭 — 앱 전역 설정. 잠금 밖이다(잠겨 있어도 열린다).
///
/// 프로필 머리 → 화면(테마) → 잠금 → 데이터(백업) → API 키 · 연결 → 위치 → 기능별 설정 → 앱 정보.
/// 기능 설정의 원본은 각 탭 ⋮ 의 "○○ 설정"이고 여기는 바로가기다. 잠금 아래 화면(물어보기 · 지도 ·
/// 일기 설정)은 [openSettings] 가 잠금 화면을 거쳐 연다.
///
/// [active] 가 켜질 때와 위에 연 화면이 닫힐 때 잠금 · 프로필 · 연결 · 위치 기록 상태를 다시 읽는다.
class SettingsTab extends StatefulWidget {
  const SettingsTab({required this.active, super.key});

  /// 이 탭이 보이는지.
  final bool active;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  void initState() {
    super.initState();
    if (widget.active) _refresh();
  }

  @override
  void didUpdateWidget(SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _refresh();
  }

  void _refresh() {
    context.read<ProfileCubit>().load();
    unawaited(context.read<DiarySettingsCubit>().load());
    unawaited(context.read<ConnectionStatusCubit>().load());
    unawaited(context.read<MapRecordCubit>().load());
  }

  Future<void> _open(SettingsTarget target) async {
    await openSettings(context, target);
    if (mounted) _refresh();
  }

  Future<void> _openProfile() async {
    await ProfilePage.open(context);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget shortcut(
      SettingsTarget target,
      IconData icon,
      String title, {
      Widget? subtitle,
    }) => AppListTile(
      key: Key('settings-open-${target.name}'),
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(_open(target)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkShellTabSettings)),
      body: ListView(
        children: [
          _ProfileHeader(onTap: () => unawaited(_openProfile())),
          const Divider(),
          SettingsSectionHeader(l10n.walkAppSettingsDisplay),
          const _ThemeSettingsRadios(),
          SettingsSectionHeader(l10n.walkAppSettingsLock),
          const LockSettingsSection(),
          SettingsSectionHeader(l10n.walkSettingsData),
          shortcut(
            SettingsTarget.backup,
            Icons.backup_outlined,
            l10n.walkBackupSettingsTitle,
          ),
          SettingsSectionHeader(l10n.walkSettingsConnections),
          // 외부 서비스 키 행이 늘면(길찾기 ODsay 등) 이 아래에 더한다. 상태는 ConnectionStatusCubit.
          shortcut(
            SettingsTarget.chat,
            Icons.key_outlined,
            l10n.walkSettingsAiConnection,
            subtitle: const _AiConnectionLabel(),
          ),
          SettingsSectionHeader(l10n.walkSettingsLocation),
          shortcut(
            SettingsTarget.map,
            Icons.my_location_outlined,
            l10n.walkMapSettingsRecord,
            subtitle: const _LocationRecordLabel(),
          ),
          SettingsSectionHeader(l10n.walkAppSettingsFeatures),
          shortcut(
            SettingsTarget.diary,
            Icons.book_outlined,
            l10n.walkDiarySettingsTitle,
          ),
          shortcut(
            SettingsTarget.alarm,
            Icons.alarm_outlined,
            l10n.walkAlarmSettingsTitle,
          ),
          shortcut(
            SettingsTarget.walk,
            Icons.directions_walk,
            l10n.walkWalkSettingsTitle,
          ),
          SettingsSectionHeader(l10n.walkSettingsAbout),
          AppListTile(
            key: const Key('settings-licenses'),
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.walkSettingsLicenses),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                showLicensePage(context: context, applicationName: 'Life Log'),
          ),
        ],
      ),
    );
  }
}

/// 프로필 머리 — 아바타 · 이름 · 한 줄 소개. 누르면 편집.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        final named = profile.name.trim().isNotEmpty;
        return AppListTile(
          key: const Key('settings-profile'),
          leading: ProfileAvatar(
            name: profile.name,
            photoPath: state.photoPath,
          ),
          title: Text(named ? profile.name : l10n.walkProfileCreate),
          subtitle: Text(
            named
                ? (profile.bio.isEmpty ? l10n.walkProfileTitle : profile.bio)
                : l10n.walkProfileCreateHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );
      },
    );
  }
}

/// AI 연결 행 부제 — 연결된 벤더 이름 또는 "연결 안 됨". 읽기 전이면 비운다.
class _AiConnectionLabel extends StatelessWidget {
  const _AiConnectionLabel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = context.watch<ConnectionStatusCubit>().state;
    if (!status.loaded) return const SizedBox.shrink();
    final ai = status.ai;
    return Text(
      ai == null ? l10n.walkSettingsAiNotConnected : chatVendorName(l10n, ai),
    );
  }
}

/// 위치 기록 행 부제 — 꺼짐 · 켜짐 · 켜짐 · 자세히 기록 · 멈춤. 읽기 전이면 비운다.
class _LocationRecordLabel extends StatelessWidget {
  const _LocationRecordLabel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<MapRecordCubit, MapRecordState>(
      buildWhen: (a, b) => a.status != b.status || a.loaded != b.loaded,
      builder: (context, state) {
        if (!state.loaded) return const SizedBox.shrink();
        return Text(switch (state.status) {
          RecorderOff() => l10n.walkSettingsLocationOff,
          RecorderBlocked() => l10n.walkSettingsLocationBlocked,
          RecorderRunning(:final mode) =>
            mode == RecordMode.dense
                ? l10n.walkSettingsLocationDetailed
                : l10n.walkSettingsLocationOn,
        });
      },
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
