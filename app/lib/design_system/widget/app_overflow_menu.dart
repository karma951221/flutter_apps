import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// `PopupMenuButton<T>` 을 감싼 공통 "더보기" 메뉴.
///
/// 게시물 카드, 댓글 목록, 프로필 화면 세 곳이 모두 수정·삭제·신고 같은 항목을
/// 아이콘 하나로 접어 두는 같은 모양을 필요로 한다. 화면마다 `PopupMenuButton`
/// 을 직접 꾸미면 툴팁·아이콘·destructive 색이 곧 어긋나므로, 반복되는 모양을
/// 여기로 승격한다 (CLAUDE.md UI 공통 위젯 규칙 4).
///
/// [items] 가 비어 있으면 아무것도 그리지 않는다 — 호출부가 "이 사용자에게는
/// 수정 권한이 없다" 같은 경우를 매번 조건문으로 감싸지 않고, 빈 리스트를
/// 넘기는 것만으로 메뉴를 숨길 수 있게 하기 위해서다.
///
/// [enabled] 가 `false` 면 `PopupMenuButton` 자체를 비활성화해 메뉴가 아예
/// 열리지 않는다 — `onSelected` 만 `null` 로 두면 메뉴는 열리고 항목도 눌리는
/// 것처럼 보이는데 아무 반응이 없는 "죽은 메뉴"가 된다. 프로필 AppBar가 차단
/// 호출이 진행 중인 동안 메뉴를 잠글 때 쓴다(`profile_page`의
/// `BlockActionState.isBlocking`).
class AppOverflowMenu<T> extends StatelessWidget {
  const AppOverflowMenu({
    required this.items,
    required this.onSelected,
    this.tooltip = '더보기',
    this.enabled = true,
    super.key,
  });

  final List<AppOverflowMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: const Icon(Icons.more_vert),
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      enabled: enabled,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final item in items)
          PopupMenuItem(
            value: item.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    color: item.isDestructive ? scheme.error : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  item.label,
                  style: item.isDestructive
                      ? TextStyle(color: scheme.error)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// [AppOverflowMenu] 가 보여주는 한 항목.
///
/// [isDestructive] 는 삭제처럼 되돌릴 수 없는 항목에 쓴다 — 라벨을
/// `colorScheme.error` 로 그려 다른 항목과 구분한다.
class AppOverflowMenuItem<T> {
  const AppOverflowMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool isDestructive;
}
