import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/walk_photo.dart';

/// 상세 화면의 사진 그리드 — 3열 정사각 썸네일.
class WalkPhotoGrid extends StatelessWidget {
  const WalkPhotoGrid({
    required this.photos,
    required this.photoFile,
    super.key,
  });

  final List<WalkPhoto> photos;
  final File Function(String relativePath) photoFile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      children: [
        for (final (index, photo) in photos.indexed)
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: Image.file(
              photoFile(photo.path),
              key: Key('walk-detail-photo-$index'),
              fit: BoxFit.cover,
              cacheWidth: 400,
              errorBuilder: (_, _, _) => ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
