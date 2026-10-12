import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/media/media_store.dart';
import '../../../domain/diary/usecase/story_cover.dart';

/// 스토리 바의 한 칸: 원(표지 사진 · 이니셜 또는 [icon]) + 아래 이름. 고른 칸은 테두리로 표시한다.
///
/// `AppAvatar` 는 '프로필 사진' 으로 읽히고(시맨틱 라벨이 아바타) 아이콘 칸(전체 · 보관함)을
/// 그리지 못해 넓히지 않고 따로 둔다. 원은 [StoryCoverCircle] — 스토리 관리 목록도 같은 원을 쓴다.
class StoryAvatar extends StatelessWidget {
  const StoryAvatar({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.image,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// 있으면 이니셜 대신 그린다.
  final IconData? icon;

  /// 표지 사진(영상이면 썸네일) 파일. 읽지 못하면 이니셜이 남는다.
  final File? image;

  /// 칸 너비. 시각 토큰이 아니라 이 위젯의 크기다.
  static const _width = 72.0;
  static const _ring = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: SizedBox(
          width: _width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0),
                      width: _ring,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(_ring),
                    child: StoryCoverCircle(
                      label: label,
                      icon: icon,
                      image: image,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? colors.primary : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 스토리 표지 원: [image] 가 있으면 사진, 없거나 읽지 못하면 [icon] · 이름 첫 글자.
class StoryCoverCircle extends StatelessWidget {
  const StoryCoverCircle({
    required this.label,
    this.icon,
    this.image,
    this.radius = defaultRadius,
    super.key,
  });

  /// 스토리 바 원 반지름. 시각 토큰이 아니라 이 위젯의 크기다.
  static const defaultRadius = 28.0;

  final String label;
  final IconData? icon;
  final File? image;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first;
    final file = image;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      // 원 크기만큼만 디코딩한다.
      foregroundImage: file == null
          ? null
          : ResizeImage(
              FileImage(file),
              width: (radius * 2 * MediaQuery.devicePixelRatioOf(context))
                  .round(),
            ),
      // 파일이 없거나 깨졌으면 아래 이니셜이 그대로 보인다.
      onForegroundImageError: file == null ? null : (_, _) {},
      child: icon == null
          ? Text(initial, style: theme.textTheme.titleMedium)
          : Icon(icon),
    );
  }
}

/// 스토리 id → 표지 그림 파일(사진, 영상이면 썸네일). 이니셜 표지는 빠진다.
/// 미디어 표지가 하나도 없으면 [MediaStore] 를 찾지 않는다.
Map<String, File> coverFiles(Map<String, StoryCover> covers) {
  final paths = <String, String>{
    for (final MapEntry(:key, :value) in covers.entries)
      if (value case CoverMedia(:final media)) key: ?_imagePath(media),
  };
  if (paths.isEmpty) return const {};
  final store = getIt<MediaStore>();
  return {
    for (final MapEntry(:key, :value) in paths.entries)
      key: store.resolve(value),
  };
}

String? _imagePath(EntryMedia media) =>
    media.kind == MediaKind.photo ? media.path : media.thumbPath;
