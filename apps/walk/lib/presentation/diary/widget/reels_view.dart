import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../theme/walk_theme.dart';
import 'entry_media_view.dart';
import 'entry_meta.dart';

/// 릴스: 한 화면에 기록 하나. 세로로 다음 기록, 가로로 같은 기록의 다음 미디어.
/// 영상은 보이는 기록 · 보이는 장만 재생한다 — 넘기면 그 영상 자리는 트리에서 빠진다.
/// 미디어 위에 글이 얹히므로 앱 테마와 상관없이 어두운 테마로 그린다.
class ReelsView extends StatefulWidget {
  const ReelsView({
    required this.entries,
    required this.now,
    required this.storyNameOf,
    required this.onOpen,
    this.videoBuilder = videoSurface,
    super.key,
  });

  /// 최신순.
  final List<DiaryEntry> entries;
  final DateTime now;
  final String? Function(DiaryEntry) storyNameOf;
  final ValueChanged<DiaryEntry> onOpen;
  final VideoSurfaceBuilder videoBuilder;

  @override
  State<ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends State<ReelsView> {
  var _current = 0;

  @override
  Widget build(BuildContext context) => Theme(
    data: WalkTheme.dark(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: widget.entries.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, i) {
            final entry = widget.entries[i];
            return _ReelsPage(
              key: ValueKey(entry.id),
              entry: entry,
              now: widget.now,
              storyName: widget.storyNameOf(entry),
              active: i == _current,
              onTap: () => widget.onOpen(entry),
              videoBuilder: widget.videoBuilder,
            );
          },
        ),
      ),
    ),
  );
}

class _ReelsPage extends StatelessWidget {
  const _ReelsPage({
    required this.entry,
    required this.now,
    required this.storyName,
    required this.active,
    required this.onTap,
    required this.videoBuilder,
    super.key,
  });

  final DiaryEntry entry;
  final DateTime now;
  final String? storyName;
  final bool active;
  final VoidCallback onTap;
  final VideoSurfaceBuilder videoBuilder;

  /// 미디어 위 글에 깔리는 그늘의 가장 진한 불투명도.
  static const _scrimAlpha = 0.6;

  /// 미디어 위에 겹치는 글의 최대 줄 수. 전부는 누르면 여는 화면에서 본다.
  static const _overlayLines = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrim = theme.colorScheme.scrim;
    final hasMedia = entry.media.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasMedia)
            MediaPager(
              media: entry.media,
              playing: active,
              fit: BoxFit.contain,
              videoBuilder: videoBuilder,
            )
          else
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(entry.body, style: theme.textTheme.titleLarge),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scrim.withValues(alpha: 0),
                    scrim.withValues(alpha: _scrimAlpha),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EntryMeta(entry: entry, now: now, storyName: storyName),
                    if (hasMedia && entry.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.body,
                        style: theme.textTheme.bodyLarge,
                        maxLines: _overlayLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      EntryTags(tags: entry.tags),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
