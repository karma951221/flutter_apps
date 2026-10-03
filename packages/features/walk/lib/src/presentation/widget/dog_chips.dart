import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/dog.dart';

/// 반려견 다중 선택 칩. [photoFile] 이 null 이면 사진 없이 이니셜 아바타를 쓴다.
class DogChips extends StatelessWidget {
  const DogChips({
    required this.dogs,
    required this.selectedIds,
    required this.onToggle,
    this.photoFile,
    this.keyPrefix = 'walk-active-dog-chip',
    super.key,
  });

  final List<Dog> dogs;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  /// 상대 경로의 사진을 파일로 푼다(`WalkUseCase.photoFile`).
  final File Function(String relativePath)? photoFile;

  /// 칩 키는 `<keyPrefix>-<id>`. 화면마다 접두사를 달리한다.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final dog in dogs)
        FilterChip(
          key: Key('$keyPrefix-${dog.id}'),
          avatar: AppAvatar(
            nickname: dog.name,
            radius: AppSpacing.md,
            imageFile: switch ((dog.photoPath, photoFile)) {
              (final String path, final resolve?) => resolve(path),
              _ => null,
            },
          ),
          label: Text(dog.name),
          selected: selectedIds.contains(dog.id),
          onSelected: (_) => onToggle(dog.id),
        ),
    ],
  );
}
