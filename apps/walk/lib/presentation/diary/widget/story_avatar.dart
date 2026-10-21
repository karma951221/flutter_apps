import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/media/media_store.dart';
import '../../../domain/diary/usecase/story_cover.dart';

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

/// 스토리의 표시 이름. 기본 스토리처럼 title 이 비면 l10n 기본 제목.
String storyDisplayTitle(AppLocalizations l10n, Story story) =>
    story.title.isEmpty ? l10n.walkDiaryDailyStoryTitle : story.title;
