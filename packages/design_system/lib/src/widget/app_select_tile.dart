import 'package:flutter/material.dart';

import 'app_list_tile.dart';

/// 보기 중 하나를 고르는 행 — 고른 행에만 오른쪽에 primary 색 체크.
class AppSelectTile extends StatelessWidget {
  const AppSelectTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.enabled = true,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: AppListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      enabled: enabled,
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    ),
  );
}
