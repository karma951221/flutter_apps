import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// 목록 · 설정 아래의 보조 설명 문단 — `bodySmall` · onSurfaceVariant.
///
/// 여백은 목록 행의 글자 줄(좌우 [AppSpacing.md])에 맞춘다.
class AppFootnote extends StatelessWidget {
  const AppFootnote(
    this.text, {
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.md,
    ),
    this.textAlign,
    super.key,
  });

  final String text;
  final EdgeInsetsGeometry padding;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Text(
        text,
        textAlign: textAlign,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
