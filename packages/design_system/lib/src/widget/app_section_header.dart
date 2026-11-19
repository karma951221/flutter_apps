import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// 목록 안 묶음의 머리 — `titleSmall` · primary 색.
///
/// 한 화면에 묶음이 둘 이상이면 모든 묶음에 단다. 묶음 사이는 이 머리의 위쪽
/// 여백으로 나누고 `Divider` 는 따로 두지 않는다.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {this.trailing, super.key});

  final String title;

  /// 머리 줄 오른쪽 — '모두 보기' 같은 작은 버튼 하나.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: trailing == null
            ? text
            : Row(
                children: [
                  Expanded(child: text),
                  trailing!,
                ],
              ),
      ),
    );
  }
}
