import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/walk/entity/walk_photo.dart';
import '../../theme/pawlog_theme.dart';

/// 상세 화면의 사진들 — 본문 폭을 가득 채운 4:3 을 세로로 잇는다(design.md Layout).
/// 모서리는 4, 인화한 사진처럼 거의 각지다.
class WalkPhotos extends StatelessWidget {
  const WalkPhotos({required this.photos, required this.photoFile, super.key});

  final List<WalkPhoto> photos;
  final File Function(String relativePath) photoFile;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, photo) in photos.indexed) ...[
          if (index > 0) const SizedBox(height: PawlogSpacing.sm),
          ClipRRect(
            borderRadius: PawlogRadius.photoAll,
            child: AspectRatio(
              aspectRatio: PawlogSize.photoAspect,
              child: Image.file(
                photoFile(photo.path),
                key: Key('walk-detail-photo-$index'),
                fit: BoxFit.cover,
                cacheWidth: (width * dpr).round(),
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colors.mapBg,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
