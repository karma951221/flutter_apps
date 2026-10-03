import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';

/// 목록 대신 화면을 채우는 안내 — 비어 있음 · 실패에 함께 쓴다.
///
/// 두 상태가 "(아이콘 +) 한 줄 안내 + (필요하면) 행동 하나"로 모양이 같다.
/// 원래는 `FeedPlaceholder` · `_ProfileLoadError` · `_BlockedUsersError` ·
/// `_CommentError` 네 벌이 각자 조금씩 다른 여백과 정렬로 같은 것을 그리고
/// 있었다 — 승격 기준("반복 사용되거나 새 화면에도 공통으로 쓸 모양")을 이미
/// 넘겨서 여기로 올렸다 (2026-08-27 리뷰).
///
/// 스스로 스크롤을 만들지 않는다. 당겨서 새로고침이 비어 있는 화면에서도
/// 동작해야 하므로 스크롤 뷰는 목록 쪽이 감싼다.
class AppPlaceholder extends StatelessWidget {
  const AppPlaceholder({
    required this.message,
    this.icon,
    this.description,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    super.key,
  });

  /// 상황을 알리는 한 줄.
  final String message;

  /// 없으면 그리지 않는다. 오류 안내처럼 문구만으로 충분한 자리가 있다.
  final IconData? icon;

  /// 한 줄로 부족할 때만 덧붙이는 보조 설명.
  final String? description;

  /// 행동 버튼 라벨. [onAction] 과 함께 있어야 그린다.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 행동 버튼을 가리키는 키. 테스트·화면이 재시도 버튼을 찾을 때 쓴다.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = actionLabel;
    final action = onAction;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppSpacing.xl * 1.5,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (label != null && action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton.secondary(
              key: actionKey,
              label: label,
              onPressed: action,
            ),
          ],
        ],
      ),
    );
  }
}
