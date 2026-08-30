import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_confirm_dialog.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../post/domain/entity/post.dart';
import '../../../post/domain/entity/post_author.dart';
import '../../../post/presentation/cubit/post_cubit.dart';
import '../../../post/presentation/widget/post_tile.dart';
import '../../../safety/domain/entity/report_target.dart';
import '../../../safety/presentation/cubit/block_action_cubit.dart';
import '../../domain/entity/feed_post.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../widget/feed_list_footer.dart';
import '../widget/post_tile_actions.dart';
import '../../../../l10n/app_localizations.dart';

/// 피드 목록 화면.
///
/// 목록은 [FeedCubit] 이, 게시물 변경은 [PostCubit] 이 소유한다. 변경 결과를
/// 목록 상태에 반영해 전체 재조회 없이 화면을 맞춘다.
///
/// 하단 내비게이션 셸의 탭 본문으로도 쓰이므로 화면 밖으로 나가는 동작(로그아웃
/// 등)을 AppBar 에 두지 않는다. 새로고침도 당겨서 새로고침 하나로 모았다 —
/// 같은 일을 하는 입구가 둘이면 AppBar 만 붐빈다.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => getIt<FeedCubit>()..load()),
      BlocProvider(create: (_) => getIt<PostCubit>()),
      BlocProvider(create: (_) => getIt<BlockActionCubit>()),
    ],
    child: const _FeedView(),
  );
}

class _FeedView extends StatelessWidget {
  const _FeedView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    // 방금 쓴 글을 목록에 넣을 때 쓸 작성자. 본인이므로 세션 값으로 충분하다.
    final currentAuthor = switch (authState) {
      AuthAuthenticated(:final user) => PostAuthor(
        id: user.id,
        nickname: user.nickname,
        avatarUrl: user.avatarUrl,
      ),
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('daylog')),
      body: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) => switch (state.status) {
          FeedStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          FeedStatus.failure => Center(
            child: AppPlaceholder(
              icon: Icons.cloud_off_outlined,
              message: state.failure?.message ?? l10n.feedLoadFailed,
              description: l10n.feedLoadFailedDescription,
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<FeedCubit>().load(),
            ),
          ),
          FeedStatus.loaded => _FeedList(
            items: state.items,
            currentUserId: currentAuthor?.id ?? '',
            isLoadingMore: state.isLoadingMore,
            canLoadMore: state.canLoadMore,
            onCompose: () => _compose(context, currentAuthor),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: l10n.feedComposeTooltip,
        onPressed: () => _compose(context, currentAuthor),
        icon: const Icon(Icons.edit),
        label: Text(l10n.feedComposeLabel),
      ),
    );
  }

  Future<void> _compose(BuildContext context, PostAuthor? author) async {
    final feed = context.read<FeedCubit>();
    final created = await context.push<Post>(Routes.postCompose);
    if (created == null) return;

    // 세션이 없는데 작성에 성공하는 경로는 없다. 그래도 작성자를 지어내지
    // 않고 재조회로 물러선다 — 잘못된 이름이 목록에 남는 것보다 낫다.
    if (author == null) {
      await feed.refresh();
      return;
    }
    feed.prependPost(FeedPost(post: created, author: author));
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.items,
    required this.currentUserId,
    required this.isLoadingMore,
    required this.canLoadMore,
    required this.onCompose,
  });

  /// 목록 맨 아래가 확장 FAB 에 가리지 않도록 두는 여백.
  static const _fabClearance = AppSpacing.xl * 3;

  final List<FeedPost> items;
  final String currentUserId;
  final bool isLoadingMore;
  final bool canLoadMore;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _empty(context);

    return RefreshIndicator(
      onRefresh: () => context.read<FeedCubit>().refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 240 &&
              !isLoadingMore &&
              canLoadMore) {
            context.read<FeedCubit>().loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: _fabClearance,
          ),
          // 마지막 한 칸은 항상 꼬리표 자리다. 더 읽는 중인지 끝까지 읽었는지를
          // 그 자리에서 구분해 알린다.
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == items.length) {
              return FeedListFooter(
                isLoadingMore: isLoadingMore,
                canLoadMore: canLoadMore,
              );
            }

            final item = items[index];
            final post = item.post;
            final isMine = post.authorId == currentUserId;
            return PostTile(
              post: post,
              author: item.author,
              isMine: isMine,
              reactions: item.reactions,
              commentCount: item.commentCount,
              onTap: isMine
                  ? () => PostTileActions.edit(context, post)
                  : () => context.push(Routes.userProfilePath(item.author.id)),
              onEdit: isMine ? () => PostTileActions.edit(context, post) : null,
              onDelete: isMine
                  ? () => PostTileActions.confirmDelete(context, post)
                  : null,
              onReport: isMine
                  ? null
                  : () => PostTileActions.report(
                      context,
                      ReportTarget.post(post.id),
                    ),
              onBlock: isMine ? null : () => _block(context, item.author.id),
              onReaction: (type) =>
                  PostTileActions.react(context, post.id, type),
              onComment: () => PostTileActions.openComments(context, item),
            );
          },
        ),
      ),
    );
  }

  /// 비어 있는 화면에서도 당겨서 새로고침이 되어야 하므로 안내를 스크롤 뷰
  /// 안에 넣는다. 화면 높이만큼 최소 높이를 줘서 가운데에 놓는다.
  Widget _empty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () => context.read<FeedCubit>().refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: AppPlaceholder(
                icon: Icons.edit_note_outlined,
                message: l10n.feedEmptyMessage,
                description: l10n.feedEmptyDescription,
                actionLabel: l10n.feedEmptyAction,
                onAction: onCompose,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 차단은 되돌릴 수 없이 상대의 글을 통째로 지운다 — 삭제와 같은 무게로
  /// 확인을 받는다 (`account_settings_page` 의 탈퇴 확인과 같은 모양).
  /// 성공해도 상대가 나를 차단했는지 여부는 절대 드러내지 않는다.
  ///
  /// 실제 차단 호출은 [BlockActionCubit] 이 한다 — 화면은 확인 다이얼로그와
  /// 성공 후 목록 반영(`removeAuthor`), 스낵바만 소유한다.
  Future<void> _block(BuildContext context, String authorId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.safetyBlockConfirmTitle,
      content: l10n.safetyBlockConfirmMessage,
      confirmLabel: l10n.safetyBlockConfirmAction,
    );
    if (!confirmed || !context.mounted) return;

    final feed = context.read<FeedCubit>();
    final blockAction = context.read<BlockActionCubit>();
    final succeeded = await blockAction.block(authorId);
    if (!context.mounted) return;

    if (succeeded) {
      feed.removeAuthor(authorId);
      AppSnackBar.show(
        context,
        message: l10n.safetyBlockSucceeded,
        type: AppSnackBarType.success,
      );
    } else {
      AppSnackBar.show(
        context,
        message: blockAction.state.failure?.message ?? l10n.safetyBlockFailed,
        type: AppSnackBarType.error,
      );
    }
  }
}
