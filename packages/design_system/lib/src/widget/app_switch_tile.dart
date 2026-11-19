import 'package:flutter/material.dart';

import 'app_list_tile.dart';

/// 켜고 끄는 행 — 행 어디를 눌러도 바뀐다.
///
/// `SwitchListTile` 과 `AppListTile` + `Switch` 가 섞이면 어떤 행은 글자를 눌러도
/// 바뀌고 어떤 행은 스위치만 눌린다. 이 위젯 하나로 맞춘다.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.switchKey,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool value;

  /// null 이면 행 전체가 꺼진다.
  final ValueChanged<bool>? onChanged;

  /// 안쪽 `Switch` 에 붙는 키 — 테스트가 스위치를 바로 찾을 때 쓴다.
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: AppListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        enabled: onChanged != null,
        trailing: Switch(key: switchKey, value: value, onChanged: onChanged),
        onTap: onChanged == null ? null : () => onChanged(!value),
      ),
    );
  }
}
