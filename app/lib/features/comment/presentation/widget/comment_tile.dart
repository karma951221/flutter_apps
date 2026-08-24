import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_overflow_menu.dart';
import '../../../reaction/domain/entity/reaction_type.dart';
import '../../../reaction/presentation/widget/reaction_bar.dart';
import '../../domain/entity/post_comment.dart';

/// 댓글 또는 답글 하나.
///
/// 답글은 [isReply] 로 들여쓰기만 달라진다. 별도 위젯으로 나누지 않는 이유는
/// depth 가 2단 고정이라 변형이 하나뿐이기 때문이다.
///
/// 삭제된 댓글([PostComment.isDeleted])은 본문 자리에 안내만 남기고 감정·답글
/// 버튼을 그리지 않는다. 본문이 없는 것은 앱의 판단이 아니라 뷰가 내려준
/// 사실이다 — 답글이 남아 있어서 자리만 지키고 있는 부모다.
///
/// 우측 상단 메뉴도 같은 이유로 삭제된 댓글에는 그리지 않는다. 살아 있는
/// 댓글이면 내 댓글은 삭제를, 남의 댓글은 신고를 보여준다.
class CommentTile extends StatelessWidget {
  const CommentTile({
    required this.comment,
    required this.isMine,
    required this.onReaction,
    this.isReply = false,
    this.onReply,
    this.onDelete,
    this.onReport,
    this.onToggleReplies,
    this.isExpanded = false,
    super.key,
  });

  final PostComment comment;
  final bool isMine;
  final bool isReply;
  final ValueChanged<ReactionType> onReaction;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onToggleReplies;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isReply ? AppSpacing.xl : AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            nickname: comment.author.nickname,
            imageUrl: comment.author.avatarUrl,
            radius: isReply ? 14 : 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_displayDate(comment.createdAt), style: mutedStyle),
                    const Spacer(),
                    if (!comment.isDeleted)
                      AppOverflowMenu<_CommentAction>(
                        tooltip: '댓글 메뉴',
                        onSelected: (action) => switch (action) {
                          _CommentAction.delete => onDelete?.call(),
                          _CommentAction.report => onReport?.call(),
                        },
                        items: [
                          if (isMine && onDelete != null)
                            const AppOverflowMenuItem(
                              value: _CommentAction.delete,
                              label: '삭제',
                              isDestructive: true,
                            ),
                          if (!isMine && onReport != null)
                            const AppOverflowMenuItem(
                              value: _CommentAction.report,
                              label: '신고',
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (comment.isDeleted)
                  Text(
                    '삭제된 댓글입니다',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    comment.content ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                if (!comment.isDeleted)
                  Row(
                    children: [
                      ReactionBar(
                        summary: comment.reactions,
                        onTap: onReaction,
                      ),
                      if (onReply != null)
                        TextButton(
                          onPressed: onReply,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('답글', style: theme.textTheme.labelMedium),
                        ),
                    ],
                  ),
                if (!isReply && comment.replyCount > 0)
                  TextButton.icon(
                    onPressed: onToggleReplies,
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(
                      isExpanded ? '답글 숨기기' : '답글 ${comment.replyCount}개 보기',
                      style: theme.textTheme.labelMedium,
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayDate(DateTime value) {
    final date = value.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month.$day $hour:$minute';
  }
}

enum _CommentAction { delete, report }
