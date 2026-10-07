import 'package:flutter/material.dart';

import 'package:l10n/l10n.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// 페이지 목록의 맨 끝에 붙는 공통 상태 줄.
///
/// [animate] 를 켜면 로딩 스피너 · 끝 안내 · 빈 칸 사이를 크로스페이드로 넘기고
/// 높이도 부드럽게 바꾼다. 꺼져 있으면 상태가 바뀌는 순간 목록 끝이 툭 튄다.
class AppListFooter extends StatelessWidget {
  const AppListFooter({
    required this.isLoadingMore,
    required this.canLoadMore,
    this.animate = false,
    super.key,
  });

  final bool isLoadingMore;

  /// 다음 커서가 남아 있는지. 없으면 마지막 페이지까지 읽었다는 뜻이다.
  final bool canLoadMore;

  /// 상태 전환을 애니메이션으로 보여줄지. 기본 false.
  ///
  /// 켜도 시스템 '애니메이션 줄이기'면 전환 없이 바로 바꾼다.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!animate || !AppMotion.enabled(context)) return content;

    // 세 상태가 각자 키를 가져야 `AnimatedSwitcher` 가 바뀐 것을 알아챈다.
    final stateKey = isLoadingMore
        ? 'loading'
        : canLoadMore
        ? 'idle'
        : 'end';
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.standard,
        switchOutCurve: AppMotion.standard,
        child: KeyedSubtree(key: ValueKey(stateKey), child: content),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
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
