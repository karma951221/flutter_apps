import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';

/// 인증 화면 상단의 제목 영역.
///
/// 세 화면이 같은 자리에서 시작하도록 제목·설명을 한 위젯으로 모은다.
/// 앱 이름(wordmark)은 첫 진입 화면인 로그인에서만 보여준다 — 하위 화면에서
/// 반복하면 지금 무슨 작업 중인지가 오히려 흐려진다.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.description,
    this.title,
    this.showWordmark = false,
    super.key,
  });

  /// 화면 이름. 로그인처럼 wordmark 로 충분한 화면에서는 생략한다.
  final String? title;

  /// 화면이 무엇을 하는 곳인지 한 문장으로 설명한다.
  final String description;

  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showWordmark) ...[
          Text(
            'daylog',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (title != null) ...[
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
