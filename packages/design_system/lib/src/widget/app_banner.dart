import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// 안내 띠의 성격.
enum AppBannerTone { info, warning, error }

/// 화면 위쪽이나 목록 사이에 놓는 안내 띠 — 아이콘 · 문구 · (행동 하나).
///
/// 권한 없음 · 일시 정지 · 받아오기 실패처럼 "지금 이 화면이 평소와 다르다"를
/// 알리는 자리에 쓴다. 성격([tone])에 따라 바탕색과 기본 아이콘만 바뀐다.
class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.message,
    this.tone = AppBannerTone.info,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.margin = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    super.key,
  });

  final String message;
  final AppBannerTone tone;

  /// 문구 위 굵은 한 줄. 없으면 문구만.
  final String? title;

  /// 없으면 [tone] 의 기본 아이콘.
  final IconData? icon;

  /// 행동 버튼 라벨. [onAction] 과 함께 있어야 그린다.
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground, defaultIcon) = switch (tone) {
      AppBannerTone.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.info_outline,
      ),
      AppBannerTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.warning_amber_outlined,
      ),
      AppBannerTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
    };
    final label = actionLabel;
    final action = onAction;
    final title = this.title;
    return Padding(
      padding: margin,
      child: Material(
        color: background,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon ?? defaultIcon, color: foreground),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null) ...[
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: foreground,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                          Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (label != null && action != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    key: actionKey,
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      minimumSize: const Size(64, 40),
                    ),
                    onPressed: action,
                    child: Text(label),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
