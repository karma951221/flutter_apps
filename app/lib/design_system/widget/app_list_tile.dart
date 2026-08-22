import 'package:flutter/material.dart';

/// 목록 행의 간격과 모양을 공통 테마에 맞춰 제공한다.
class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    title: title,
    subtitle: subtitle,
    leading: leading,
    trailing: trailing,
    enabled: enabled,
    onTap: onTap,
  );
}
