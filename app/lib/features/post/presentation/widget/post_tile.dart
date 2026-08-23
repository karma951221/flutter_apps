import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_count_action.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../../reaction/domain/entity/reaction_summary.dart';
import '../../../reaction/domain/entity/reaction_type.dart';
import '../../../reaction/presentation/widget/reaction_bar.dart';
import '../../domain/entity/post.dart';
import '../../domain/entity/post_author.dart';

/// 목록에서 게시물 하나를 보여준다.
///
/// feed 와 profile 이 함께 쓰므로 소유자가 명확한 post 가 들고 있는다
/// (아키텍처 규칙 ⑥).
///
/// [author] 를 옵션으로 두지 않는다. 값이 없을 때 보여줄 그럴듯한 대체 표시를
/// 만들면 조인을 빠뜨린 화면이 조용히 넘어간다. 목록을 만드는 쪽이 작성자를
/// 함께 가져오도록 타입으로 강제한다.
///
/// 반응·댓글 줄은 [onReaction] 이 있을 때만 그린다. 게시물만 보여주는 화면이
/// 누를 수 없는 버튼을 그리지 않게 하기 위해서다. 감정 위젯은 reaction feature
/// 가 소유하고 여기서 import 한다 (아키텍처 규칙 ⑥ — 소유자가 명확한 쪽에 둔다).
class PostTile extends StatelessWidget {
  const PostTile({
    required this.post,
    required this.author,
    required this.isMine,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.reactions = const ReactionSummary(),
    this.commentCount = 0,
    this.onReaction,
    this.onComment,
    super.key,
  });

  final Post post;
  final PostAuthor author;
  final bool isMine;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// 감정 집계와 내 반응. 목록 뷰가 항목과 함께 내려준 값이다.
  final ReactionSummary reactions;

  /// 살아 있는 댓글과 답글의 합.
  final int commentCount;

  /// 감정을 눌렀을 때. null 이면 반응·댓글 줄을 그리지 않는다.
  final ValueChanged<ReactionType>? onReaction;

  /// 댓글 화면으로 가는 동작.
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: AppListTile(
        onTap: onTap,
        leading: AppAvatar(
          nickname: author.nickname,
          imageUrl: author.avatarUrl,
          radius: 20,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                author.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(_displayDate(post.updatedAt), style: mutedStyle),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.images.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      // 목록을 되감을 때마다 1080px 원본을 다시 받지 않도록
                      // 디스크 캐시를 쓴다. 로딩·실패도 위젯 트리로 던지지 않고
                      // 같은 크기의 자리를 지키는 상자로 대신한다.
                      child: CachedNetworkImage(
                        imageUrl: post.images[index].url,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _imagePlaceholder(scheme),
                        errorWidget: (_, _, _) => _imagePlaceholder(
                          scheme,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (onReaction != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    ReactionBar(summary: reactions, onTap: onReaction),
                    AppCountAction(
                      icon: Icons.mode_comment_outlined,
                      count: commentCount,
                      tooltip: '댓글',
                      onPressed: onComment,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: isMine
            ? PopupMenuButton<_PostAction>(
                tooltip: '게시물 메뉴',
                onSelected: (action) => switch (action) {
                  _PostAction.edit => onEdit?.call(),
                  _PostAction.delete => onDelete?.call(),
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _PostAction.edit, child: Text('수정')),
                  PopupMenuItem(value: _PostAction.delete, child: Text('삭제')),
                ],
              )
            : null,
      ),
    );
  }

  /// 이미지가 아직 없거나 실패했을 때 같은 크기의 자리를 지키는 상자.
  Widget _imagePlaceholder(ColorScheme scheme, {Widget? child}) {
    return Container(
      width: 160,
      height: 160,
      alignment: Alignment.center,
      color: scheme.surfaceContainerHighest,
      child: child,
    );
  }

  String _displayDate(DateTime value) {
    final date = value.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}.$month.$day $hour:$minute';
  }
}

enum _PostAction { edit, delete }
