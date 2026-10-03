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

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // 한 칸의 논리 너비 — 화면 너비를 열 수로 나눈 값에서 간격을 뺀다.
    final cell =
        (MediaQuery.sizeOf(context).width - AppSpacing.xs * (_columns - 1)) /
        _columns;
    return GridView.count(
      crossAxisCount: _columns,
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
              cacheWidth: (cell * dpr).round(),
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
