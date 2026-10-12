import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/media_limits.dart';
import 'entry_media_view.dart';

/// 어디서 사진 · 영상을 가져올지.
enum MediaSource { gallery, photo, video }

/// 작성 화면의 '사진·영상 추가' 버튼 + 고른 미디어 가로 줄(길게 눌러 끌면 순서 바꾸기).
class MediaStrip extends StatelessWidget {
  const MediaStrip({
    required this.media,
    required this.importing,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    super.key,
  });

  final List<EntryMedia> media;

  /// 압축 중이면 버튼 대신 진행 표시.
  final bool importing;
  final ValueChanged<MediaSource> onAdd;
  final ValueChanged<String> onRemove;

  /// [from] 자리의 미디어를 [to] 자리(뺀 뒤 목록 기준)로.
  final void Function(int from, int to) onReorder;

  /// 썸네일 한 변. 시각 토큰이 아니라 이 줄의 크기다.
  static const thumbSize = 88.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final full = !MediaLimits.canAdd(media.length, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              AppButton.secondary(
                // 앱 테마 버튼은 폭을 가득 채운다(`Size.fromHeight`) — 줄 안이라 최소 크기만 푼다.
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size.zero),
                ),
                label: l10n.walkDiaryEditorAddMedia,
                isLoading: importing,
                onPressed: full ? null : () => _chooseSource(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${media.length}/${MediaLimits.maxItems}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (media.isNotEmpty)
          SizedBox(
            height: thumbSize + AppSpacing.md,
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              onReorder: (from, to) => onReorder(from, to > from ? to - 1 : to),
              children: [
                for (final m in media)
                  Padding(
                    key: ValueKey(m.id),
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _Thumb(media: m, onRemove: () => onRemove(m.id)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _chooseSource(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<MediaSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (source, icon, label) in [
              (
                MediaSource.gallery,
                Icons.photo_library_outlined,
                l10n.walkDiaryEditorPickGallery,
              ),
              (
                MediaSource.photo,
                Icons.photo_camera_outlined,
                l10n.walkDiaryEditorTakePhoto,
              ),
              (
                MediaSource.video,
                Icons.videocam_outlined,
                l10n.walkDiaryEditorTakeVideo,
              ),
            ])
              AppListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.of(sheetContext).pop(source),
              ),
          ],
        ),
      ),
    );
    if (source != null) onAdd(source);
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.media, required this.onRemove});

  final EntryMedia media;
  final VoidCallback onRemove;

  /// 빼기 버튼 바탕의 불투명도 — 사진 위에서도 보이게.
  static const _buttonAlpha = 0.8;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: MediaStrip.thumbSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: EntryMediaView(media: media),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context).walkDiaryEditorRemoveMedia,
              style: IconButton.styleFrom(
                backgroundColor: colors.surface.withValues(alpha: _buttonAlpha),
              ),
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}
