import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/social/entity/walk_post.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';
import '../../walk/widget/route_sketch.dart';

/// 모두의 산책 한 줄 — 피드 항목과 같은 줄글(카드 없음, design.md).
///
/// 작성자(아바타 · 닉네임) · 날짜 → 반려견 이름 → 경로 그림(있을 때만) → 거리 · 시간 → 메모 →
/// 하트. 글은 공유한 순서라 날짜가 섞이므로 피드의 날짜 열 대신 줄마다 날짜를 쓴다.
class CommunityPostEntry extends StatelessWidget {
  const CommunityPostEntry({
    required this.post,
    required this.onLike,
    super.key,
  });

  final WalkPost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final styles = PawlogTextStyles.of(context);
    final theme = Theme.of(context);
    final memo = post.memo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PawlogSize.gutter,
        0,
        PawlogSize.gutter,
        PawlogSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(
                nickname: post.authorNickname,
                imageUrl: post.authorAvatarUrl,
                radius: PawlogSize.avatarSm,
              ),
              const SizedBox(width: PawlogSpacing.sm),
              Expanded(
                child: Text(
                  post.authorNickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: PawlogSpacing.sm),
              Text(
                post.startedAt.displayDateTime(l10n.localeName),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: PawlogSpacing.sm),
          Text(
            post.dogNames.join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styles.dogName,
          ),
          if (post.routePreview.length >= 2) ...[
            const SizedBox(height: PawlogSpacing.sm),
            ClipRRect(
              borderRadius: PawlogRadius.photoAll,
              child: AspectRatio(
                aspectRatio: PawlogSize.photoAspect,
                child: RouteSketch(points: post.routePreview),
              ),
            ),
          ],
          const SizedBox(height: PawlogSpacing.sm),
          Wrap(
            spacing: PawlogSpacing.md,
            children: [
              Text(
                WalkFormat.distance(l10n, post.distanceMeters),
                style: styles.number,
              ),
              Text(
                WalkFormat.duration(l10n, post.duration),
                style: styles.number,
              ),
            ],
          ),
          // 빈 메모는 자리를 차지하지 않는다.
          if (memo != null && memo.trim().isNotEmpty) ...[
            const SizedBox(height: PawlogSpacing.xs),
            Text(
              memo,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: styles.memo,
            ),
          ],
          const SizedBox(height: PawlogSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppCountAction(
              key: Key('community-like-${post.id}'),
              icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
              count: post.likeCount,
              tooltip: l10n.walkSocialLikeTooltip,
              isActive: post.likedByMe,
              animate: true,
              onPressed: onLike,
            ),
          ),
        ],
      ),
    );
  }
}
