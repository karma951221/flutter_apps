import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../domain/entity/post.dart';

/// 목록에서 게시물 하나를 보여준다.
///
/// feed 와 profile 이 함께 쓰므로 소유자가 명확한 post 가 들고 있는다
/// (아키텍처 규칙 ⑥).
class PostTile extends StatelessWidget {
  const PostTile({
    required this.post,
    required this.isMine,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final Post post;
  final bool isMine;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: AppListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(post.authorId.characters.first.toUpperCase()),
        ),
        title: Text(
          post.content,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            _displayDate(post.updatedAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
