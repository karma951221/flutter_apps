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
import '../../domain/entity/feed_post.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../widget/feed_post_tile.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<FeedCubit>()..load(),
    child: const _FeedView(),
  );
}

class _FeedView extends StatelessWidget {
  const _FeedView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userId = switch (authState) {
      AuthAuthenticated(:final user) => user.id,
      _ => '',
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
            posts: state.posts,
            currentUserId: userId,
            isLoadingMore: state.isLoadingMore,
            canLoadMore: state.canLoadMore,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: '새 게시물 작성',
        onPressed: () => _openEditor(context, Routes.feedCompose),
        icon: const Icon(Icons.edit),
        label: const Text('작성'),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, String path) async {
    await context.push(path);
    if (context.mounted) await context.read<FeedCubit>().refresh();
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.posts,
    required this.currentUserId,
    required this.isLoadingMore,
    required this.canLoadMore,
  });

  final List<FeedPost> posts;
  final String currentUserId;
  final bool isLoadingMore;
  final bool canLoadMore;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<FeedCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('아직 작성된 피드가 없습니다.')),
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
          itemCount: posts.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == posts.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final post = posts[index];
            return FeedPostTile(
              post: post,
              isMine: post.authorId == currentUserId,
              onTap: post.authorId == currentUserId
                  ? () => _openEditor(context, post)
                  : () {},
              onEdit: () => _openEditor(context, post),
              onDelete: () => _confirmDelete(context, post),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, FeedPost post) async {
    await context.push(Routes.feedEditPath(post.id), extra: post);
    if (context.mounted) await context.read<FeedCubit>().refresh();
  }

  Future<void> _confirmDelete(BuildContext context, FeedPost post) async {
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

    final result = await context.read<FeedCubit>().delete(post.id);
    if (!context.mounted) return;
    result.when(
      ok: (_) => AppSnackBar.show(
        context,
        message: '게시물을 삭제했습니다.',
        type: AppSnackBarType.success,
      ),
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
