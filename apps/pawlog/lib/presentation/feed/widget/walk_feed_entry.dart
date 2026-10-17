import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/walk.dart';
import '../../dog/widget/dog_avatars.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';
import '../../walk/widget/route_sketch.dart';

/// 피드 타임라인의 한 줄 — 카드가 아니라 수첩의 한 칸이다(design.md Components · 피드 항목).
///
/// 왼쪽 날짜 열(일 · 요일, 아래로 리드줄) + 오른쪽 본문 열(아바타 · 이름 · 시각 → 사진 또는 경로 →
/// 거리 · 시간 → 메모). 같은 날의 두 번째 기록부터는 [showDate] 가 거짓이라 날짜 없이 리드줄만
/// 이어지고, [continuesBelow] 가 참이면 다음 기록까지 리드줄이 끊기지 않는다.
class WalkFeedEntry extends StatelessWidget {
  const WalkFeedEntry({
    required this.walk,
    required this.photoFile,
    required this.onTap,
    required this.showDate,
    required this.continuesBelow,
    super.key,
  });

  final Walk walk;
  final File Function(String relativePath) photoFile;
  final VoidCallback onTap;
  final bool showDate;
  final bool continuesBelow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final styles = PawlogTextStyles.of(context);
    final theme = Theme.of(context);
    final startedAt = walk.startedAt.toLocal();
    final memo = walk.memo;
    final names = walk.dogs.map((dog) => dog.name).join(', ');

    final lead = SizedBox(
      width: PawlogSize.leadLine,
      child: ColoredBox(color: colors.primary),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PawlogSize.gutter),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: PawlogSize.dateColumn,
                child: Column(
                  children: [
                    if (showDate) ...[
                      Text(
                        '${startedAt.day}',
                        key: Key('walk-feed-date-${walk.id}'),
                        style: styles.feedDay,
                      ),
                      Text(
                        DateFormat.E(l10n.localeName).format(startedAt),
                        style: styles.feedWeekday,
                      ),
                      const SizedBox(height: PawlogSpacing.sm),
                    ],
                    Expanded(child: lead),
                    // 그날의 마지막 기록이면 리드줄은 본문 끝에서 멈추고 다음 날과 떨어진다.
                    if (!continuesBelow)
                      const SizedBox(height: PawlogSpacing.xl),
                  ],
                ),
              ),
              const SizedBox(width: PawlogSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: PawlogSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (walk.dogs.isNotEmpty) ...[
                            DogAvatars(dogs: walk.dogs, photoFile: photoFile),
                            const SizedBox(width: PawlogSpacing.sm),
                          ],
                          Expanded(
                            child: Text(
                              names,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: styles.dogName,
                            ),
                          ),
                          const SizedBox(width: PawlogSpacing.sm),
                          if (walk.isFavorite) ...[
                            Icon(
                              Icons.star,
                              key: Key('walk-feed-favorite-${walk.id}'),
                              size: PawlogSize.favoriteIcon,
                              color: colors.primary,
                            ),
                            const SizedBox(width: PawlogSpacing.xs),
                          ],
                          Text(
                            DateFormat.Hm(l10n.localeName).format(startedAt),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: PawlogSpacing.sm),
                      ClipRRect(
                        borderRadius: PawlogRadius.photoAll,
                        child: AspectRatio(
                          aspectRatio: PawlogSize.photoAspect,
                          child: _Visual(walk: walk, photoFile: photoFile),
                        ),
                      ),
                      const SizedBox(height: PawlogSpacing.sm),
                      Wrap(
                        spacing: PawlogSpacing.md,
                        children: [
                          Text(
                            WalkFormat.distance(l10n, walk.distanceMeters),
                            style: styles.number,
                          ),
                          Text(
                            WalkFormat.duration(l10n, walk.duration),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 달이 바뀌는 곳에 한 번 — 날짜 열이 '일' 만 보여서 달이 섞이면 읽을 수 없다.
class WalkFeedMonthHeader extends StatelessWidget {
  const WalkFeedMonthHeader({required this.month, super.key});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PawlogSize.gutter,
        PawlogSpacing.lg,
        PawlogSize.gutter,
        PawlogSpacing.md,
      ),
      child: Text(
        DateFormat.yMMMM(l10n.localeName).format(month),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colors.textMuted),
      ),
    );
  }
}

/// 첫 사진(4:3, 본문 폭) — 없거나 못 읽으면 같은 자리에 경로 썸네일.
class _Visual extends StatelessWidget {
  const _Visual({required this.walk, required this.photoFile});

  final Walk walk;
  final File Function(String relativePath) photoFile;

  @override
  Widget build(BuildContext context) {
    final route = RouteSketch(points: walk.previewPoints);
    if (walk.photos.isEmpty) return route;

    // 본문 폭은 화면 폭보다 좁다 — 화면 폭으로 디코드하면 넉넉하다. LayoutBuilder 는
    // 피드 항목의 IntrinsicHeight 안에서 쓸 수 없다.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.file(
      photoFile(walk.photos.first.path),
      fit: BoxFit.cover,
      cacheWidth: (MediaQuery.sizeOf(context).width * dpr).round(),
      errorBuilder: (_, _, _) => route,
    );
  }
}
