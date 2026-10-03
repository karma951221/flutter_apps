import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/walk.dart';
import '../format/walk_format.dart';
import 'dog_avatars.dart';
import 'route_preview_painter.dart';

/// 피드의 산책 카드 한 장. 바탕은 Material `Card` + `InkWell` 이다 —
/// `design_system` 에 썸네일 큰 카드 위젯이 없고 쓰는 곳이 피드 하나뿐이라 승격하지 않았다.
class WalkCard extends StatelessWidget {
  const WalkCard({
    required this.walk,
    required this.photoFile,
    required this.onTap,
    super.key,
  });

  final Walk walk;
  final File Function(String relativePath) photoFile;
  final VoidCallback onTap;

  static const _thumbnailSize = 88.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final memo = walk.memo;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (walk.dogs.isNotEmpty) ...[
                      DogAvatars(dogs: walk.dogs, photoFile: photoFile),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Text(
                      walk.startedAt.displayDateTime(l10n.localeName),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${WalkFormat.distance(l10n, walk.distanceMeters)}'
                      ' · ${WalkFormat.duration(l10n, walk.duration)}',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (memo != null && memo.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        memo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: SizedBox.square(
                  dimension: _thumbnailSize,
                  child: _Thumbnail(walk: walk, photoFile: photoFile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.walk, required this.photoFile});

  final Walk walk;
  final File Function(String relativePath) photoFile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final route = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: walk.previewPoints.length < 2
          ? Icon(Icons.pets_outlined, color: scheme.onSurfaceVariant)
          : CustomPaint(
              painter: RoutePreviewPainter(
                walk.previewPoints,
                color: scheme.primary,
              ),
            ),
    );
    if (walk.photos.isEmpty) return route;

    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.file(
      photoFile(walk.photos.first.path),
      fit: BoxFit.cover,
      cacheWidth: (WalkCard._thumbnailSize * dpr).round(),
      errorBuilder: (_, _, _) => route,
    );
  }
}
