import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reaction/feature_reaction.dart';
import '../../../trade/domain/entity/trade_result_summary.dart';
import '../../../trade/presentation/widget/trade_result_card.dart';
import '../../domain/entity/post.dart';
import '../../domain/entity/post_author.dart';
import '../../domain/entity/post_image.dart';
import 'package:l10n/l10n.dart';

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
///
/// 우측 상단 메뉴는 내 글일 때만 그리는 것이 아니다 — 내 글은 수정·삭제를,
/// 남의 글은 신고·차단을 보여준다. 콜백이 모두 null 이면 [AppOverflowMenu] 가
/// 스스로 아무것도 그리지 않는다.
///
/// 판 결과 카드([TradeResultCard])는 trade feature 가 소유하고 여기서 import
/// 한다. **post → trade 는 아키텍처 규칙 ⑥ 이 허용하는 유일한 역방향 참조다** —
/// 카드의 모양·색·표기는 모의투자 화면들과 한 몸이라 trade 쪽에 두는 것이 맞고,
/// 그걸 목록에 놓을 수 있는 자리는 여기뿐이다. 반대 방향(trade → post)이나
/// 이 밖의 역참조는 만들지 않는다.
class PostTile extends StatelessWidget {
  const PostTile({
    required this.post,
    required this.author,
    required this.isMine,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onBlock,
    this.reactions = const ReactionSummary(),
    this.commentCount = 0,
    this.onReaction,
    this.onComment,
    this.onTradeResultTap,
    super.key,
  });

  final Post post;
  final PostAuthor author;
  final bool isMine;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  /// 이 게시물의 작성자를 차단하는 동작. 남의 글에만 뜨는 것은 신고 항목과
  /// 같은 방어([!isMine])를 받는다.
  final VoidCallback? onBlock;

  /// 감정 집계와 내 반응. 목록 뷰가 항목과 함께 내려준 값이다.
  final ReactionSummary reactions;

  /// 살아 있는 댓글과 답글의 합.
  final int commentCount;

  /// 감정을 눌렀을 때. null 이면 반응·댓글 줄을 그리지 않는다.
  final ValueChanged<ReactionType>? onReaction;

  /// 댓글 화면으로 가는 동작.
  final VoidCallback? onComment;

  /// 붙어 있는 판 결과를 눌렀을 때. 인자는 결과 화면으로 들어갈 판 id 다.
  /// null 이면 카드는 그려지되 누를 수 없다.
  final ValueChanged<String>? onTradeResultTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
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
            Text(
              post.updatedAt.displayDateTime(l10n.localeName),
              style: mutedStyle,
            ),
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
              if (post.tradeResult case final TradeResultSummary summary) ...[
                const SizedBox(height: AppSpacing.sm),
                TradeResultCard(
                  summary: summary,
                  onTap: onTradeResultTap == null
                      ? null
                      : () => onTradeResultTap!(summary.sessionId),
                ),
              ],
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _PostImages(images: post.images),
              ],
              if (onReaction != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    ReactionBar(summary: reactions, onTap: onReaction),
                    AppCountAction(
                      icon: Icons.mode_comment_outlined,
                      count: commentCount,
                      tooltip: l10n.postCommentCountTooltip,
                      onPressed: onComment,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: AppOverflowMenu<_PostAction>(
          tooltip: l10n.postMenuTooltip,
          onSelected: (action) => switch (action) {
            _PostAction.edit => onEdit?.call(),
            _PostAction.delete => onDelete?.call(),
            _PostAction.report => onReport?.call(),
            _PostAction.block => onBlock?.call(),
          },
          items: [
            if (isMine && onEdit != null)
              AppOverflowMenuItem(
                value: _PostAction.edit,
                label: l10n.postMenuEdit,
              ),
            if (isMine && onDelete != null)
              AppOverflowMenuItem(
                value: _PostAction.delete,
                label: l10n.commonDelete,
                isDestructive: true,
              ),
            if (!isMine && onReport != null)
              AppOverflowMenuItem(
                value: _PostAction.report,
                label: l10n.postMenuReport,
              ),
            if (!isMine && onBlock != null)
              AppOverflowMenuItem(
                value: _PostAction.block,
                label: l10n.postMenuBlockUser,
                isDestructive: true,
              ),
          ],
        ),
      ),
    );
  }
}

enum _PostAction { edit, delete, report, block }

/// 게시물에 붙은 사진.
///
/// 한 장일 때는 가로를 채우고 **원본 비율을 지킨다**. 목록에서 사진 한 장짜리
/// 게시물이 대부분인데, 고정 정사각형으로 잘라 보여주면 세로 사진이 크게 상한다.
/// 여러 장일 때는 카드 높이를 예측 가능하게 두는 쪽이 중요해서 정사각 썸네일
/// 가로 스크롤을 유지한다.
class _PostImages extends StatelessWidget {
  const _PostImages({required this.images});

  static const _thumbnailSize = 160.0;

  /// 한 장짜리가 카드를 다 잡아먹지 않도록 두는 상한.
  static const _maxSingleHeight = 320.0;

  final List<PostImage> images;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (images.length == 1) {
      final image = images.single;
      return ClipRRect(
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _maxSingleHeight),
          child: AspectRatio(
            // 치수를 목록 조회가 함께 내려주므로 이미지를 받기 전에 자리를
            // 잡을 수 있다. 나중에 크기가 바뀌며 목록이 튀지 않는다.
            aspectRatio: image.width / image.height,
            child: _image(image.url, scheme, fit: BoxFit.cover),
          ),
        ),
      );
    }

    return SizedBox(
      height: _thumbnailSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) => ClipRRect(
          borderRadius: AppRadius.smAll,
          child: SizedBox(
            width: _thumbnailSize,
            height: _thumbnailSize,
            child: _image(images[index].url, scheme),
          ),
        ),
      ),
    );
  }

  /// 목록을 되감을 때마다 1080px 원본을 다시 받지 않도록 디스크 캐시를 쓴다.
  /// 로딩·실패도 위젯 트리로 던지지 않고 같은 자리를 지키는 상자로 대신한다.
  Widget _image(String url, ColorScheme scheme, {BoxFit fit = BoxFit.cover}) =>
      CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, _) => _placeholder(scheme),
        errorWidget: (_, _, _) => _placeholder(
          scheme,
          child: Icon(
            Icons.broken_image_outlined,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _placeholder(ColorScheme scheme, {Widget? child}) => ColoredBox(
    color: scheme.surfaceContainerHighest,
    child: Center(child: child),
  );
}
