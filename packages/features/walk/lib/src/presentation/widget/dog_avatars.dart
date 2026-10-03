import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/dog.dart';

/// 겹쳐 놓은 반려견 아바타 줄. [maxVisible] 을 넘는 몫은 `+n` 으로 접는다.
/// 상세 화면과 피드 카드가 함께 쓴다.
class DogAvatars extends StatelessWidget {
  const DogAvatars({
    required this.dogs,
    required this.photoFile,
    this.maxVisible = 3,
    this.radius = AppSpacing.md,
    super.key,
  });

  final List<Dog> dogs;

  /// 상대 경로의 사진을 파일로 푼다(`WalkUseCase.photoFile`).
  final File Function(String relativePath) photoFile;
  final int maxVisible;
  final double radius;

  /// 아바타끼리 겹치는 정도 — 지름의 이 비율만큼씩 옆으로 민다.
  static const _step = 0.7;

  @override
  Widget build(BuildContext context) {
    if (dogs.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final visible = dogs.take(maxVisible).toList();
    final hidden = dogs.length - visible.length;
    final slots = visible.length + (hidden > 0 ? 1 : 0);
    final diameter = radius * 2;
    final border = AppSpacing.xs / 2;
    final offset = diameter * _step;

    Widget ring(Widget child) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.surface, width: border),
      ),
      child: child,
    );

    return SizedBox(
      width: offset * (slots - 1) + diameter + border * 2,
      height: diameter + border * 2,
      child: Stack(
        children: [
          for (final (index, dog) in visible.indexed)
            Positioned(
              left: offset * index,
              child: ring(
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
              child: ring(
                CircleAvatar(
                  radius: radius,
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
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
