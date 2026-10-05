import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../domain/dog/entity/dog.dart';
import '../../theme/pawlog_theme.dart';

/// 겹쳐 놓은 반려견 아바타 줄. [maxVisible] 을 넘는 몫은 `+n` 으로 접는다.
/// 상세 화면과 피드 항목이 함께 쓴다.
///
/// 여러 마리면 12 씩 겹치고, 바탕색 2px 테두리로 떼어낸다(design.md Shapes).
class DogAvatars extends StatelessWidget {
  const DogAvatars({
    required this.dogs,
    required this.photoFile,
    this.maxVisible = 3,
    this.radius = PawlogSize.avatarSm,
    super.key,
  });

  final List<Dog> dogs;

  /// 상대 경로의 사진을 파일로 푼다(`WalkUseCase.photoFile`).
  final File Function(String relativePath) photoFile;
  final int maxVisible;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (dogs.isEmpty) return const SizedBox.shrink();

    final colors = PawlogColors.of(context);
    final visible = dogs.take(maxVisible).toList();
    final hidden = dogs.length - visible.length;
    final slots = visible.length + (hidden > 0 ? 1 : 0);
    const ring = PawlogSize.avatarRing;
    final diameter = radius * 2 + ring * 2;
    final offset = diameter - PawlogSize.avatarOverlap;

    Widget ringed(Widget child) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.paper, width: ring),
      ),
      child: child,
    );

    return SizedBox(
      width: offset * (slots - 1) + diameter,
      height: diameter,
      child: Stack(
        children: [
          for (final (index, dog) in visible.indexed)
            Positioned(
              left: offset * index,
              child: ringed(
                AppAvatar(
                  nickname: dog.name,
                  radius: radius,
                  imageFile: switch (dog.photoPath) {
                    final String path => photoFile(path),
                    null => null,
                  },
                ),
              ),
            ),
          if (hidden > 0)
            Positioned(
              left: offset * visible.length,
              child: ringed(
                CircleAvatar(
                  radius: radius,
                  backgroundColor: colors.rule,
                  foregroundColor: colors.text,
                  child: Text(
                    '+$hidden',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
