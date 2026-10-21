import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import 'entry_media_view.dart';

/// 기록 3열 정사각 그리드(스펙 §3.3) — 스크롤 뷰 하나로 쓸 때. 머리를 위에 얹으려면
/// [SliverEntryGrid] 를 `CustomScrollView` 에 넣는다.
class EntryGrid extends StatelessWidget {
  const EntryGrid({required this.entries, required this.onOpen, super.key});

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpen;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [SliverEntryGrid(entries: entries, onOpen: onOpen)],
  );
}

/// 기록 3열 정사각 그리드의 슬리버. 최신 기록이 위다(받은 순서와 상관없이 `occurredAt` 내림차순).
///
/// 칸은 기록의 첫 미디어 썸네일(영상이면 ▶), 미디어가 여럿이면 겹침 아이콘, 글만 있으면 글 앞부분.
class SliverEntryGrid extends StatelessWidget {
  const SliverEntryGrid({
    required this.entries,
    required this.onOpen,
    super.key,
  });

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpen;

  /// 한 줄 칸 수.
  static const _columns = 3;

  /// 칸 사이 틈. 시각 토큰이 아니라 이 그리드의 선 굵기다.
  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisSpacing: _gap,
        crossAxisSpacing: _gap,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final entry = sorted[i];
        return _EntryCell(
          key: ValueKey('grid-${entry.id}'),
          entry: entry,
          onTap: () => onOpen(entry),
        );
      },
    );
  }
}

class _EntryCell extends StatelessWidget {
  const _EntryCell({required this.entry, required this.onTap, super.key});

  final DiaryEntry entry;
  final VoidCallback onTap;

  /// 글 칸에 보이는 줄 수.
  static const _textLines = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final media = entry.media;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: media.isEmpty
          ? ColoredBox(
              color: colors.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  entry.body,
                  maxLines: _textLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // 영상은 썸네일 위에 ▶ 를 그린다.
                EntryMediaView(media: media.first),
                if (media.length > 1)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.collections_outlined,
                        size: AppSpacing.md,
                        color: colors.onInverseSurface,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
