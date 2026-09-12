import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import '../../../post/domain/entity/post_author.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:feature_safety/feature_safety.dart';
import '../../domain/comment_policy.dart';
import '../../domain/entity/post_comment.dart';
import '../cubit/comment_cubit.dart';
import '../cubit/comment_state.dart';
import '../widget/comment_tile.dart';

/// 한 게시물의 댓글 화면.
///
/// 나갈 때 최종 댓글 수를 돌려준다. 피드가 그 값으로 항목 하나만 고치므로
/// 목록을 다시 읽지 않는다 ([initialCount] + `CommentState.countDelta`).
class PostCommentsPage extends StatelessWidget {
  const PostCommentsPage({
    required this.postId,
    this.initialCount = 0,
    super.key,
  });

  final String postId;
  final int initialCount;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CommentCubit>()..load(postId),
    child: _CommentView(initialCount: initialCount),
  );
}

class _CommentView extends StatefulWidget {
  const _CommentView({required this.initialCount});

  final int initialCount;

  @override
  State<_CommentView> createState() => _CommentViewState();
}

class _CommentViewState extends State<_CommentView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// 답글을 달 부모. null 이면 일반 댓글이다.
  PostComment? _replyTarget;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUser = switch (context.watch<AuthBloc>().state) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    final author = currentUser == null
        ? null
        : PostAuthor(
            id: currentUser.id,
            nickname: currentUser.nickname,
            avatarUrl: currentUser.avatarUrl,
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final delta = context.read<CommentCubit>().state.countDelta;
        Navigator.of(context).pop(widget.initialCount + delta);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.commentTitle)),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<CommentCubit, CommentState>(
                builder: (context, state) => switch (state.status) {
                  CommentStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  CommentStatus.failure => Center(
                    child: AppPlaceholder(
                      message:
                          state.failure?.localizedMessage(context) ??
                          l10n.commentLoadFailed,
                      actionLabel: l10n.commonRetry,
                      onAction: () => context.read<CommentCubit>().refresh(),
                    ),
                  ),
                  CommentStatus.loaded => _CommentList(
                    state: state,
                    currentUserId: author?.id ?? '',
                    onReply: _startReply,
                  ),
                },
              ),
            ),
            _CommentComposer(
              controller: _controller,
              focusNode: _focusNode,
              replyTarget: _replyTarget,
              author: author,
              onCancelReply: () => setState(() => _replyTarget = null),
              onSubmitted: () => setState(() => _replyTarget = null),
            ),
          ],
        ),
      ),
    );
  }

  void _startReply(PostComment target) {
    setState(() => _replyTarget = target);
    _focusNode.requestFocus();
  }
}

class _CommentList extends StatelessWidget {
  const _CommentList({
    required this.state,
    required this.currentUserId,
    required this.onReply,
  });

  final CommentState state;
  final String currentUserId;
  final ValueChanged<PostComment> onReply;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<CommentCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            Center(
              child: Text(AppLocalizations.of(context).commentEmptyMessage),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CommentCubit>().refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 240 &&
              !state.isLoadingMore &&
              state.canLoadMore) {
            context.read<CommentCubit>().loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final comment = state.items[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommentTile(
                  comment: comment,
                  isMine: comment.author.id == currentUserId,
                  isExpanded: state.isExpanded(comment.id),
                  onReaction: (type) => _react(context, comment, type),
                  // 삭제된 부모에는 답글을 달 수 없다. 최종 판정은 트리거다.
                  onReply: comment.isDeleted ? null : () => onReply(comment),
                  onDelete: () => _confirmDelete(context, comment),
                  onReport: () => _report(context, comment),
                  onToggleReplies: () =>
                      context.read<CommentCubit>().toggleReplies(comment.id),
                ),
                if (state.isExpanded(comment.id)) ...[
                  for (final reply in state.repliesOf(comment.id))
                    CommentTile(
                      comment: reply,
                      isReply: true,
                      isMine: reply.author.id == currentUserId,
                      onReaction: (type) => _react(context, reply, type),
                      onDelete: () => _confirmDelete(context, reply),
                      onReport: () => _report(context, reply),
                    ),
                  if (state.isLoadingReplies(comment.id))
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.canLoadMoreReplies(comment.id))
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xl),
                      child: AppButton.text(
                        label: AppLocalizations.of(
                          context,
                        ).commentLoadMoreReplies,
                        onPressed: () => context
                            .read<CommentCubit>()
                            .loadMoreReplies(comment.id),
                      ),
                    ),
                ],
                const Divider(height: 1),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _react(
    BuildContext context,
    PostComment comment,
    ReactionType type,
  ) async {
    final result = await context.read<CommentCubit>().toggleReaction(
      comment,
      type,
    );
    if (!context.mounted) return;

    result.when(
      ok: (_) {},
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.localizedMessage(context),
        type: AppSnackBarType.error,
      ),
    );
  }

  Future<void> _report(BuildContext context, PostComment comment) async {
    final l10n = AppLocalizations.of(context);
    final filed = await ReportSheet.show(
      context,
      ReportTarget.comment(comment.id),
    );
    if (!context.mounted) return;
    if (filed) {
      AppSnackBar.show(
        context,
        message: l10n.safetyReportSubmitted,
        type: AppSnackBarType.success,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, PostComment comment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.commentDeleteConfirmTitle,
      content: l10n.commentDeleteConfirmMessage,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed || !context.mounted) return;

    final result = await context.read<CommentCubit>().delete(comment);
    if (!context.mounted) return;

    result.when(
      ok: (deleted) => AppSnackBar.show(
        context,
        message: deleted
            ? l10n.commentDeleteSucceeded
            : l10n.commentDeleteNotAllowed,
        type: deleted ? AppSnackBarType.success : AppSnackBarType.error,
      ),
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.localizedMessage(context),
        type: AppSnackBarType.error,
      ),
    );
  }
}

/// 입력 줄. 답글 대상이 있으면 그 사실을 위에 표시한다.
class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.replyTarget,
    required this.author,
    required this.onCancelReply,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PostComment? replyTarget;
  final PostAuthor? author;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final target = replyTarget;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (target != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.commentReplyingTo(target.author.nickname),
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commentReplyCancelTooltip,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onCancelReply,
                  ),
                ],
              ),
            BlocBuilder<CommentCubit, CommentState>(
              buildWhen: (previous, current) =>
                  previous.isSubmitting != current.isSubmitting,
              builder: (context, state) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLength: CommentPolicy.maxContentLength,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: target == null
                            ? l10n.commentInputHint
                            : l10n.commentReplyInputHint,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    tooltip: l10n.commentSubmitTooltip,
                    onPressed: state.isSubmitting
                        ? null
                        : () => _submit(context),
                    icon: state.isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final writer = author;
    if (writer == null) {
      AppSnackBar.show(
        context,
        message: l10n.commentSignInRequired,
        type: AppSnackBarType.error,
      );
      return;
    }

    final result = await context.read<CommentCubit>().add(
      content: controller.text,
      author: writer,
      parentId: replyTarget?.id,
    );
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        controller.clear();
        onSubmitted();
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.localizedMessage(context),
        type: AppSnackBarType.error,
      ),
    );
  }
}
