import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// 아이콘 + 개수로 된 작은 동작 버튼.
///
/// 좋아요·싫어요·댓글처럼 "누르는 곳이자 개수를 읽는 곳"인 표시가 게시물 카드와
/// 댓글 목록 양쪽에 반복된다. [AppButton] 은 아이콘 자리가 없고, 화면마다
/// `TextButton.icon` 을 직접 꾸미면 선택 상태 색과 여백이 곧 어긋난다.
///
/// [isActive] 는 "내가 누른 상태"다. 색만 바꾸고 모양은 그대로 둔다 — 목록에서
/// 여러 개가 나란히 보이므로 크기가 흔들리면 읽기 어렵다.
class AppCountAction extends StatelessWidget {
  const AppCountAction({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    super.key,
  });

  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
