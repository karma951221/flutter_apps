import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/entry_media.dart';
import 'entry_media_view.dart';

/// 작성 화면에 붙인 사진 · 영상 썸네일 줄(스펙 2026-11-15 §3). ✕ 로 빼고, 길게 눌러 끌어
/// 순서를 바꾼다. 가져오는 중이면 끝에 진행 칸을 둔다. 비어 있으면 아무것도 그리지 않는다.
class ComposerMediaStrip extends StatelessWidget {
  const ComposerMediaStrip({
    required this.media,
    required this.importing,
    required this.onRemove,
    required this.onReorder,
    super.key,
  });

  final List<EntryMedia> media;

  /// 압축 중이면 끝에 진행 표시.
  final bool importing;
  final ValueChanged<String> onRemove;

  /// [from] 자리의 미디어를 [to] 자리(뺀 뒤 목록 기준)로.
  final void Function(int from, int to) onReorder;

  /// 썸네일 한 변. 시각 토큰이 아니라 이 칸의 크기다.
  static const thumbSize = 88.0;

  /// 빼기 버튼 바탕의 불투명도 — 사진 위에서도 보이게.
  static const _buttonAlpha = 0.8;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty && !importing) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final removeLabel = AppLocalizations.of(context).walkDiaryEditorRemoveMedia;
    return SizedBox(
      height: thumbSize + AppSpacing.md,
      child: ReorderableListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        onReorder: (from, to) => onReorder(from, to > from ? to - 1 : to),
        footer: importing
            ? const SizedBox.square(
                dimension: thumbSize,
                child: Center(child: CircularProgressIndicator()),
              )
            : null,
        children: [
          for (final m in media)
            Padding(
              key: ValueKey(m.id),
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: SizedBox.square(
                dimension: thumbSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.smAll,
                      child: EntryMediaView(media: m),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton.filledTonal(
                        tooltip: removeLabel,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surface.withValues(
                            alpha: _buttonAlpha,
                          ),
                        ),
                        icon: const Icon(Icons.close),
                        onPressed: () => onRemove(m.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
