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

/// 탭 앱바 오른쪽 끝의 ⋮ — 화면별 항목, 그 아래 "○○ 설정".
///
/// 설정 화면은 [openSettings] 로 연다. 그래서 셸의 설정 cubit 다섯 아래에 있어야 한다.
/// 앱 전역 설정은 하단 설정 탭이라 여기 없다. 잠긴 동안(일기 · 지도 · 물어보기)에는
/// [showFeatureSettings] 를 꺼 항목을 모두 숨기고, 항목이 없으면 ⋮ 자체를 그리지 않는다.
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

  /// false 면 아무 항목도 없어 ⋮ 를 그리지 않는다(잠긴 동안). [entries] 도 숨긴다.
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
        AppOverflowMenuItem(
          key: Key('menu-settings-${settings.name}'),
          value: () => openSettings(context, settings),
          label: _settingsLabel(l10n, settings),
        ),
      ],
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return AppOverflowMenu<VoidCallback>(
      items: items,
      onSelected: (action) => action(),
    );
  }

  static String _settingsLabel(AppLocalizations l10n, SettingsTarget target) =>
      switch (target) {
        SettingsTarget.diary => l10n.walkDiarySettingsTitle,
        SettingsTarget.chat => l10n.walkChatSettingsTitle,
        SettingsTarget.alarm => l10n.walkAlarmSettingsTitle,
        SettingsTarget.walk => l10n.walkWalkSettingsTitle,
        SettingsTarget.map => l10n.walkMapSettingsTitle,
        SettingsTarget.backup => l10n.walkBackupSettingsTitle,
      };
}
