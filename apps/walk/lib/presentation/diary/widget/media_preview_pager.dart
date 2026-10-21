import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/media_limits.dart';
import 'entry_media_view.dart';
import 'media_source_sheet.dart';

/// 작성 화면 맨 위 큰 미리보기(스펙 §3.6): 고른 사진 · 영상을 좌우로 넘기고, 마지막 칸 ＋ 로
/// 더 고른다. 길게 누르거나 ✕ 로 뺀다. 둘 이상이면 아래 작은 썸네일 줄에서 길게 끌어 순서를 바꾼다.
class MediaPreviewPager extends StatefulWidget {
  const MediaPreviewPager({
    required this.media,
    required this.importing,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    super.key,
  });

  final List<EntryMedia> media;

  /// 압축 중이면 ＋ 칸에 진행 표시, 누를 수 없다.
  final bool importing;
  final ValueChanged<MediaSource> onAdd;
  final ValueChanged<String> onRemove;

  /// [from] 자리의 미디어를 [to] 자리(뺀 뒤 목록 기준)로.
  final void Function(int from, int to) onReorder;

  /// 미디어가 없을 때 ＋ 칸만의 높이. 시각 토큰이 아니라 이 칸의 크기다.
  static const emptyHeight = 120.0;

  /// 썸네일 줄의 한 변.
  static const thumbSize = 48.0;

  @override
  State<MediaPreviewPager> createState() => _MediaPreviewPagerState();
}

class _MediaPreviewPagerState extends State<MediaPreviewPager> {
  final _pages = PageController();

  @override
  void didUpdateWidget(MediaPreviewPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 새로 가져오면 처음 들어온 것을 보인다.
    final before = oldWidget.media.length;
    if (widget.media.length > before) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(before);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _chooseSource() async {
    final choice = await showMediaSourceSheet(context);
    final source = choice?.source;
    if (source != null) widget.onAdd(source);
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final canAdd = MediaLimits.canAdd(media.length, 1);
    final add = _AddCell(
      count: media.length,
      importing: widget.importing,
      onTap: widget.importing ? null : _chooseSource,
    );
    if (media.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SizedBox(height: MediaPreviewPager.emptyHeight, child: add),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView(
            controller: _pages,
            children: [
              for (final m in media)
                _Page(
                  key: ValueKey(m.id),
                  child: _Preview(
                    media: m,
                    onRemove: () => widget.onRemove(m.id),
                  ),
                ),
              if (canAdd) _Page(child: add),
            ],
          ),
        ),
        if (media.length > 1)
          SizedBox(
            height: MediaPreviewPager.thumbSize + AppSpacing.md,
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              onReorder: (from, to) =>
                  widget.onReorder(from, to > from ? to - 1 : to),
              children: [
                for (final (i, m) in media.indexed)
                  Padding(
                    key: ValueKey(m.id),
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () => _pages.jumpToPage(i),
                      child: SizedBox.square(
                        dimension: MediaPreviewPager.thumbSize,
                        child: ClipRRect(
                          borderRadius: AppRadius.smAll,
                          child: EntryMediaView(media: m),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 한 칸의 여백.
class _Page extends StatelessWidget {
  const _Page({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: child,
  );
}

/// 큰 미리보기 한 장. 길게 누르거나 ✕ 로 뺀다.
class _Preview extends StatelessWidget {
  const _Preview({required this.media, required this.onRemove});

  final EntryMedia media;
  final VoidCallback onRemove;

  /// 빼기 버튼 바탕의 불투명도 — 사진 위에서도 보이게.
  static const _buttonAlpha = 0.8;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onLongPress: onRemove,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: AppRadius.lgAll,
            child: EntryMediaView(media: media),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: IconButton.filledTonal(
                tooltip: AppLocalizations.of(
                  context,
                ).walkDiaryEditorRemoveMedia,
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface.withValues(
                    alpha: _buttonAlpha,
                  ),
                ),
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ＋ 칸: '사진·영상 추가' + 지금 개수. 가져오는 중에는 진행 표시.
class _AddCell extends StatelessWidget {
  const _AddCell({
    required this.count,
    required this.importing,
    required this.onTap,
  });

  final int count;
  final bool importing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (importing)
                const CircularProgressIndicator()
              else
                Icon(Icons.add_photo_alternate_outlined, color: colors.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.walkDiaryEditorAddMedia,
                style: theme.textTheme.labelLarge,
              ),
              Text(
                '$count/${MediaLimits.maxItems}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
