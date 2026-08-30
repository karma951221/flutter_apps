import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// 목록 맨 끝에 붙는 줄.
///
/// "더 읽는 중"과 "여기가 끝"은 사용자에게 전혀 다른 소식이다. 예전에는 추가
/// 로딩일 때만 진행 표시를 그리고 마지막 페이지에서는 아무것도 그리지 않아서,
/// 둘 다 "그냥 멈춘 화면"으로 보였다.
class FeedListFooter extends StatelessWidget {
  const FeedListFooter({
    required this.isLoadingMore,
    required this.canLoadMore,
    super.key,
  });

  final bool isLoadingMore;

  /// 다음 커서가 남아 있는지. 없으면 마지막 페이지까지 읽었다는 뜻이다.
  final bool canLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // 다음 페이지가 남아 있으면 곧 위 분기로 바뀐다. 그 사이에 "끝" 이라고
    // 말하지 않는다.
    if (canLoadMore) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Text(
          AppLocalizations.of(context).feedEndOfList,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
