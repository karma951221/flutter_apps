import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 산책 사진 띠. 썸네일마다 빼기 버튼이 있고, 끝에 추가 칸이 붙는다.
///
/// [photoPaths] 가 [maxPhotos] 에 닿으면 추가 칸 대신 한도 안내를 보인다.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    required this.photoPaths,
    required this.photoFile,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemove,
    this.enabled = true,
    super.key,
  });

  /// 앱 문서 폴더 기준 상대 경로, 순서대로.
  final List<String> photoPaths;
  final File Function(String relativePath) photoFile;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final bool enabled;

  static const _tileSize = AppSpacing.xl * 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isFull = photoPaths.length >= maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _tileSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photoPaths.length + (isFull ? 0 : 1),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == photoPaths.length) {
                return _AddTile(
                  key: const Key('walk-edit-add-photo'),
                  label: l10n.walkAddPhoto,
                  onTap: enabled ? onAdd : null,
                );
              }
              return _Thumbnail(
                file: photoFile(photoPaths[index]),
                imageKey: Key('walk-edit-photo-$index'),
                removeKey: Key('walk-edit-remove-photo-$index'),
                onRemove: enabled ? () => onRemove(index) : null,
              );
            },
          ),
        ),
        if (isFull) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.walkPhotoLimitReached,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.file,
    required this.imageKey,
    required this.removeKey,
    required this.onRemove,
  });

  final File file;
  final Key imageKey;
  final Key removeKey;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: PhotoStrip._tileSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: Image.file(
              file,
              key: imageKey,
              fit: BoxFit.cover,
              cacheWidth: PhotoStrip._tileSize.round() * 2,
              errorBuilder: (_, _, _) => ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: InkResponse(
              key: removeKey,
              onTap: onRemove,
              child: CircleAvatar(
                radius: AppSpacing.md - AppSpacing.xs,
                backgroundColor: scheme.scrim.withValues(alpha: 0.6),
                child: Icon(
                  Icons.close,
                  size: AppSpacing.md,
                  color: scheme.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = onTap == null ? scheme.outlineVariant : scheme.primary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: Ink(
          width: PhotoStrip._tileSize,
          height: PhotoStrip._tileSize,
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
