import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../backup/page/backup_page.dart';
import '../diary/page/diary_route.dart';
import '../map/cubit/map_record_cubit.dart';
import '../lock/cubit/diary_lock_cubit.dart';
import 'cubit/diary_settings_cubit.dart';
import 'cubit/holiday_settings_cubit.dart';
import 'cubit/settings_permissions_cubit.dart';
import 'page/alarm_settings_page.dart';
import 'page/chat_settings_page.dart';
import 'page/diary_settings_page.dart';
import 'page/map_settings_page.dart';
import 'page/walk_settings_page.dart';

/// 열 설정 화면.
enum SettingsTarget { diary, chat, alarm, walk, map, backup }

/// [openSettings] 를 부를 수 있는 자리(셸 cubit 다섯 아래)면 [target] 을 여는 콜백, 아니면 null.
/// 셸 밖에서 연 화면(예: 작성 화면이 띄운 시트)에 "설정 열기"를 넘길 때 쓴다 — 콜백은 [context] 로 연다.
VoidCallback? settingsOpener(
  BuildContext context,
  SettingsTarget target, {
  bool highlight = false,
}) {
  try {
    context
      ..read<SettingsPermissionsCubit>()
      ..read<HolidaySettingsCubit>()
      ..read<DiaryLockCubit>()
      ..read<DiarySettingsCubit>()
      ..read<MapRecordCubit>();
  } on ProviderNotFoundException {
    return null;
  }
  return () {
    if (context.mounted) {
      unawaited(openSettings(context, target, highlight: highlight));
    }
  };
}

/// [target] 설정 화면을 [context] 의 Navigator 에 push 한다.
///
/// [context] 위에 셸의 [SettingsPermissionsCubit] · [HolidaySettingsCubit] · [DiaryLockCubit] ·
/// [DiarySettingsCubit] · [MapRecordCubit] 가 있어야 한다 — 다섯을 새 라우트에 다시 건다
/// (`ThemeCubit` · `StepGoalCubit` 은 앱 위라 그대로 보인다). 설정 탭에서 여는 지도 설정도
/// 이 다섯을 읽으므로 모든 화면에 함께 건다. 같은 Navigator 라 셸의 `didPopNext` 가 돌아올 때
/// 다시 읽는다.
///
/// 일기 · 물어보기 · 지도 설정은 잠금 아래([pushDiaryRoute]) — 잠겨 있으면 잠금 화면이 먼저 보인다.
/// 백업은 잠금 밖에서 열고, 잠겨 있으면 화면이 행을 막는다.
///
/// [highlight] 가 true 면 열린 화면이 봐야 할 행을 glow 한다 — chat: 연결 행, alarm: 조치가
/// 필요한 첫 권한 행. 다른 target 에서는 무시한다.
Future<void> openSettings(
  BuildContext context,
  SettingsTarget target, {
  bool highlight = false,
}) {
  final permissions = context.read<SettingsPermissionsCubit>();
  final holiday = context.read<HolidaySettingsCubit>();
  final lock = context.read<DiaryLockCubit>();
  final diary = context.read<DiarySettingsCubit>();
  final record = context.read<MapRecordCubit>();
  Widget provide(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: permissions),
      BlocProvider.value(value: holiday),
      BlocProvider.value(value: lock),
      BlocProvider.value(value: diary),
      BlocProvider.value(value: record),
    ],
    child: child,
  );

  Future<void> push(Widget page) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => provide(page)));

  Future<void> pushLocked(Widget page) => pushDiaryRoute<void>(
    context,
    page: (_) => page,
    scope: (_, gated) => provide(gated),
  );

  return switch (target) {
    SettingsTarget.alarm => push(
      AlarmSettingsPage(highlightPermissions: highlight),
    ),
    SettingsTarget.walk => push(const WalkSettingsPage()),
    SettingsTarget.map => pushLocked(const MapSettingsPage()),
    SettingsTarget.diary => pushLocked(const DiarySettingsPage()),
    SettingsTarget.chat => pushLocked(
      ChatSettingsPage(highlightConnection: highlight),
    ),
    SettingsTarget.backup => push(const BackupPage()),
  };
}
