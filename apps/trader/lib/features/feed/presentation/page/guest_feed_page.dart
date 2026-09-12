import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_list_footer.dart';
import '../../../../design_system/widget/app_load_more_listener.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../post/presentation/widget/post_tile.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';

/// 비로그인 읽기 전용 피드.
///
/// 가입 전에 앱이 주는 것이 문장 하나뿐이었다 (상호성,
/// ux-psychology-review.md 4번). 전체 피드는 DB 가 이미 `anon` 에 열어 두었으므로
/// 라우터만 열면 된다. 블러·가림 없이 실제 내용을 그대로 보여주고, 반응·댓글·
/// 게시물 탭은 가입 안내 시트로 보낸다.
///
/// 기본 진입은 여전히 로그인 화면이다 — 이 화면은 로그인 화면의 "먼저 둘러보기"
/// 로만 들어온다.
class GuestFeedPage extends StatelessWidget {
  const GuestFeedPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<FeedCubit>()..load(),
    child: const _GuestFeedView(),
  );
}

class _GuestFeedView extends StatelessWidget {
  const _GuestFeedView();

  /// 목록 맨 아래 여백. 피드 화면과 달리 FAB 이 없지만 꼬리표가 화면 끝에
  /// 붙지 않게 한 칸 둔다.
  static const _bottomPadding = AppSpacing.xl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guestFeedTitle)),
      body: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) => switch (state.status) {
          FeedStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          FeedStatus.failure => Center(
            child: AppPlaceholder(
              icon: Icons.cloud_off_outlined,
              message:
                  state.failure?.localizedMessage(context) ??
                  l10n.feedLoadFailed,
              description: l10n.feedLoadFailedDescription,
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<FeedCubit>().refresh(),
            ),
          ),
          FeedStatus.loaded when state.items.isEmpty => Center(
            child: AppPlaceholder(
              icon: Icons.edit_note_outlined,
              message: l10n.feedEmptyMessage,
              // 읽을 것이 없어도 막다른 길로 두지 않는다 — 게스트가 여기서
              // 할 수 있는 유일한 일이 가입이다.
              actionLabel: l10n.authSignUp,
              onAction: () => _promptSignUp(context),
            ),
          ),
          FeedStatus.loaded => RefreshIndicator(
            onRefresh: () => context.read<FeedCubit>().refresh(),
            child: AppLoadMoreListener(
              onLoadMore: () {
                if (!state.isLoadingMore && state.canLoadMore) {
                  context.read<FeedCubit>().loadMore();
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: _bottomPadding,
                ),
                itemCount: state.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == state.items.length) {
                    return AppListFooter(
                      isLoadingMore: state.isLoadingMore,
                      canLoadMore: state.canLoadMore,
                    );
                  }
                  final item = state.items[index];
                  return PostTile(
                    post: item.post,
                    author: item.author,
                    isMine: false,
                    reactions: item.reactions,
                    commentCount: item.commentCount,
                    onTap: () => _promptSignUp(context),
                    onReaction: (_) => _promptSignUp(context),
                    onComment: () => _promptSignUp(context),
                    // 끝난 판의 결과는 게스트도 볼 수 있는 열린 화면이다
                    // (`Routes.openRoutes`). 여기서 가입을 권할 이유가 없다.
                    onTradeResultTap: (sessionId) =>
                        context.push(Routes.tradeResultPath(sessionId)),
                  );
                },
              ),
            ),
          ),
        },
      ),
    );
  }

  /// 무엇을 하려 했든 같은 안내다 — "가입하면 할 수 있다".
  Future<void> _promptSignUp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final action = await showModalBottomSheet<_GuestAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.guestPromptTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.guestPromptDescription,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: l10n.authSignUp,
                onPressed: () =>
                    Navigator.of(sheetContext).pop(_GuestAction.signUp),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.text(
                label: l10n.authSignIn,
                onPressed: () =>
                    Navigator.of(sheetContext).pop(_GuestAction.signIn),
              ),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case _GuestAction.signUp:
        router.push(Routes.signUp);
      case _GuestAction.signIn:
        router.go(Routes.signIn);
      case null:
        break;
    }
  }
}

enum _GuestAction { signUp, signIn }
