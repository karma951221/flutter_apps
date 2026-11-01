import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../settings/open_settings.dart';

/// [FeatureMenu] 위쪽의 화면별 항목 하나(예: 알람 기록 · 휴지통).
class FeatureMenuEntry {
  const FeatureMenuEntry({
    required this.label,
    required this.onTap,
    this.icon,
    this.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// 메뉴 행에 붙는다 — 테스트가 라벨 없이 찾게 한다.
  final Key? key;
}

/// 탭 앱바 오른쪽 끝의 ⋮ — 화면별 항목, 그 아래 "○○ 설정"과 "앱 설정".
///
/// 설정 화면은 [openSettings] 로 연다. 그래서 셸의 설정 cubit 넷 아래에 있어야 한다.
/// 잠긴 동안(일기 · 물어보기)에는 [showFeatureSettings] 를 끄고 [entries] 를 비워
/// "앱 설정"만 남긴다 — 기능 설정은 잠금 아래라서다.
class FeatureMenu extends StatelessWidget {
  const FeatureMenu({
    required this.settings,
    this.entries = const [],
    this.showFeatureSettings = true,
    super.key,
  });

  /// "○○ 설정"이 여는 곳.
  final SettingsTarget settings;

  /// 위쪽 화면별 항목.
  final List<FeatureMenuEntry> entries;

  /// false 면 "앱 설정"만(잠긴 동안). [entries] 도 숨긴다.
  final bool showFeatureSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <AppOverflowMenuItem<VoidCallback>>[
      if (showFeatureSettings) ...[
        for (final entry in entries)
          AppOverflowMenuItem(
            key: entry.key,
            value: entry.onTap,
            label: entry.label,
            icon: entry.icon,
          ),
        if (settings != SettingsTarget.app)
          AppOverflowMenuItem(
            key: Key('menu-settings-${settings.name}'),
            value: () => openSettings(context, settings),
            label: _settingsLabel(l10n, settings),
          ),
      ],
      AppOverflowMenuItem(
        key: const Key('menu-settings-app'),
        value: () => openSettings(context, SettingsTarget.app),
        label: l10n.walkAppSettingsTitle,
      ),
    ];
    return AppOverflowMenu<VoidCallback>(
      items: items,
      onSelected: (action) => action(),
    );
  }

  static String _settingsLabel(AppLocalizations l10n, SettingsTarget target) =>
      switch (target) {
        SettingsTarget.app => l10n.walkAppSettingsTitle,
        SettingsTarget.diary => l10n.walkDiarySettingsTitle,
        SettingsTarget.chat => l10n.walkChatSettingsTitle,
        SettingsTarget.alarm => l10n.walkAlarmSettingsTitle,
        SettingsTarget.walk => l10n.walkWalkSettingsTitle,
      };
}
