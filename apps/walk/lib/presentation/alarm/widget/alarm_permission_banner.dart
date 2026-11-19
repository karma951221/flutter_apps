import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 알림 · 정확한 알람 중 하나라도 거부됐을 때 목록 위 경고. [알람 설정] 이나 띠 어디를 눌러도
/// 알람 설정 화면을 열고 권한 행을 짚는다.
class AlarmPermissionBanner extends StatelessWidget {
  const AlarmPermissionBanner({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 예전 띠는 행 전체가 눌렸다 — 글자를 눌러도 열리게 띠 전체에 탭을 남긴다.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AppBanner(
        tone: AppBannerTone.error,
        title: l10n.walkAlarmPermissionWarning,
        message: l10n.walkAlarmPermissionWarningAction,
        actionLabel: l10n.walkAlarmSettingsTitle,
        onAction: onTap,
        actionKey: const Key('alarm-permission-banner-action'),
      ),
    );
  }
}
