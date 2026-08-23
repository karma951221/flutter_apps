import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../post/domain/entity/post.dart';
import '../../../post/domain/entity/post_author.dart';
import '../../../post/presentation/cubit/post_cubit.dart';
import '../../../post/presentation/widget/post_tile.dart';
import '../../../reaction/domain/entity/reaction_type.dart';
import '../../domain/entity/feed_post.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';

/// 피드 목록 화면.
///
/// 목록은 [FeedCubit] 이, 게시물 변경은 [PostCubit] 이 소유한다. 변경 결과를
/// 목록 상태에 반영해 전체 재조회 없이 화면을 맞춘다.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => getIt<FeedCubit>()..load()),
      BlocProvider(create: (_) => getIt<PostCubit>()),
    ],
    child: const _FeedView(),
  );
}

class _FeedView extends StatelessWidget {
  const _FeedView();

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text('daylog'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FeedCubit>().refresh(),
          ),
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(
              const AuthEvent.signOutRequested(),
            ),
          ),
        ],
      ),
      body: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) => switch (state.status) {
          FeedStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          FeedStatus.failure => _FeedError(
            message: state.failure?.message ?? '피드를 불러오지 못했습니다',
            onRetry: () => context.read<FeedCubit>().load(),
          ),
          FeedStatus.loaded => _FeedList(
            items: state.items,
            currentUserId: currentAuthor?.id ?? '',
            isLoadingMore: state.isLoadingMore,
            canLoadMore: state.canLoadMore,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: '새 게시물 작성',
        onPressed: () => _compose(context, currentAuthor),
        icon: const Icon(Icons.edit),
        label: const Text('작성'),
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
  });

  final List<FeedPost> items;
  final String currentUserId;
  final bool isLoadingMore;
  final bool canLoadMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<FeedCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('아직 작성된 게시물이 없습니다.')),
          ],
        ),
      );
    }

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
          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 96),
          itemCount: items.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
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
                  ? () => _edit(context, post)
                  : () => context.push(Routes.userProfilePath(item.author.id)),
              onEdit: () => _edit(context, post),
              onDelete: () => _confirmDelete(context, post),
              onReaction: (type) => _react(context, post.id, type),
              onComment: () => _openComments(context, item),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Post post) async {
    final feed = context.read<FeedCubit>();
    final updated = await context.push<Post>(
      Routes.postEditPath(post.id),
      extra: post,
    );
    if (updated != null) feed.replacePost(updated);
  }

  /// 감정은 목록이 저장하고 되돌린다. 화면은 실패만 알린다.
  Future<void> _react(
    BuildContext context,
    String postId,
    ReactionType type,
  ) async {
    final result = await context.read<FeedCubit>().toggleReaction(postId, type);
    if (!context.mounted) return;

    result.when(
      ok: (_) {},
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? '감정을 남기지 못했습니다.',
        type: AppSnackBarType.error,
      ),
    );
  }

  /// 댓글 화면은 나갈 때 최종 개수를 돌려준다. 목록을 다시 읽지 않고 그
  /// 항목의 수만 고친다.
  Future<void> _openComments(BuildContext context, FeedPost item) async {
    final feed = context.read<FeedCubit>();
    final count = await context.push<int>(
      Routes.postCommentsPath(item.id),
      extra: item.commentCount,
    );
    if (count != null) feed.applyCommentCount(item.id, count);
  }

  Future<void> _confirmDelete(BuildContext context, Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('게시물을 삭제할까요?'),
        content: const Text('삭제한 게시물은 되돌릴 수 없습니다.'),
        actions: [
          AppButton.text(
            label: '취소',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.text(
            label: '삭제',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final feed = context.read<FeedCubit>();
    final result = await context.read<PostCubit>().delete(post.id);
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        feed.removePost(post.id);
        AppSnackBar.show(
          context,
          message: '게시물을 삭제했습니다.',
          type: AppSnackBarType.success,
        );
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? '게시물을 삭제하지 못했습니다.',
        type: AppSnackBarType.error,
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(label: '다시 시도', onPressed: onRetry),
        ],
      ),
    ),
  );
}
