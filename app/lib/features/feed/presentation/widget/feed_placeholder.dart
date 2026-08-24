import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';

/// 목록 대신 화면을 채우는 안내 — 비어 있음 · 실패에 함께 쓴다.
///
/// 두 상태가 "아이콘 + 한 줄 안내 + (필요하면) 행동 하나"로 모양이 같아서 한
/// 위젯으로 묶었다. 같은 모양이 프로필·댓글 목록에도 있으므로 반복이 한 번 더
/// 생기면 `design_system/widget/` 으로 올릴 후보다 (UI 공통 위젯 규칙 4).
///
/// 스스로 스크롤을 만들지 않는다. 당겨서 새로고침이 비어 있는 화면에서도 동작해야
/// 하므로 스크롤 뷰는 목록 쪽이 감싼다.
class FeedPlaceholder extends StatelessWidget {
  const FeedPlaceholder({
    required this.icon,
    required this.message,
    this.description,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;

  /// 상황을 알리는 한 줄.
  final String message;

  /// 한 줄로 부족할 때만 덧붙이는 보조 설명.
  final String? description;

  /// 행동 버튼 라벨. [onAction] 과 함께 있어야 그린다.
  final String? actionLabel;
  final VoidCallback? onAction;

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
          Icon(icon, size: AppSpacing.xl * 1.5, color: scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
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
            AppButton.secondary(label: label, onPressed: action),
          ],
        ],
      ),
    );
  }
}
