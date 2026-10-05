import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../domain/dog/entity/dog.dart';
import '../../theme/pawlog_theme.dart';

/// 반려견 다중 선택 칩. [photoFile] 이 null 이면 사진 없이 이니셜 아바타를 쓴다.
///
/// 선택은 칩의 바탕(남색) · 테두리로만 보인다 — 체크 표시가 아바타 글자와 겹치던 것을
/// 없앴다(QA P2, `PawlogTheme.chipTheme`).
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
    spacing: PawlogSpacing.sm,
    runSpacing: PawlogSpacing.sm,
    children: [
      for (final dog in dogs)
        FilterChip(
          key: Key('$keyPrefix-${dog.id}'),
          avatar: AppAvatar(
            nickname: dog.name,
            radius: PawlogSize.avatarSm,
            imageFile: switch ((dog.photoPath, photoFile)) {
              (final String path, final resolve?) => resolve(path),
              _ => null,
            },
          ),
          label: Text(dog.name),
          selected: selectedIds.contains(dog.id),
          showCheckmark: false,
          onSelected: (_) => onToggle(dog.id),
        ),
    ],
  );
}
