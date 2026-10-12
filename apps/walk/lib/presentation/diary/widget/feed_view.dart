import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_media.dart';
import 'entry_media_view.dart';
import 'entry_meta.dart';

/// 피드: 기록마다 카드. 미디어는 좌우로 넘기고, 긴 본문은 [FeedView.foldedLines] 줄로 접는다.
class FeedView extends StatelessWidget {
  const FeedView({
    required this.entries,
    required this.now,
    required this.storyNameOf,
    required this.onOpen,
    super.key,
  });

  /// 접힌 본문의 줄 수.
  static const foldedLines = 6;

  /// 최신순.
  final List<DiaryEntry> entries;
  final DateTime now;
  final String? Function(DiaryEntry) storyNameOf;
  final ValueChanged<DiaryEntry> onOpen;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    itemCount: entries.length,
    itemBuilder: (context, i) {
      final entry = entries[i];
      return _FeedCard(
        key: ValueKey(entry.id),
        entry: entry,
        now: now,
        storyName: storyNameOf(entry),
        onTap: () => onOpen(entry),
      );
    },
  );
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.entry,
    required this.now,
    required this.storyName,
    required this.onTap,
    super.key,
  });

  final DiaryEntry entry;
  final DateTime now;
  final String? storyName;
  final VoidCallback onTap;

  /// 미디어 칸의 가로세로 비. 첫 장을 따르되 너무 길거나 납작하지 않게 묶는다.
  static double _aspect(EntryMedia first) {
    if (first.width <= 0 || first.height <= 0) return 1;
    return (first.width / first.height).clamp(4 / 5, 16 / 9);
  }

  @override
  Widget build(BuildContext context) {
    final media = entry.media;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: EntryMeta(entry: entry, now: now, storyName: storyName),
            ),
            if (media.isNotEmpty)
              AspectRatio(
                aspectRatio: _aspect(media.first),
                child: MediaPager(media: media),
              ),
            if (entry.body.isNotEmpty || entry.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.body.isNotEmpty) _FoldedBody(text: entry.body),
                    if (entry.body.isNotEmpty && entry.tags.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    EntryTags(tags: entry.tags),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [FeedView.foldedLines] 줄을 넘는 본문은 접고 "더 보기"로 펼친다.
class _FoldedBody extends StatefulWidget {
  const _FoldedBody({required this.text});

  final String text;

  @override
  State<_FoldedBody> createState() => _FoldedBodyState();
}

class _FoldedBodyState extends State<_FoldedBody> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    if (_expanded) return Text(widget.text, style: style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: FeedView.foldedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        if (!overflows) return Text(widget.text, style: style);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: FeedView.foldedLines,
              overflow: TextOverflow.ellipsis,
            ),
            AppButton.text(
              label: AppLocalizations.of(context).walkDiaryShowMore,
              onPressed: () => setState(() => _expanded = true),
            ),
          ],
        );
      },
    );
  }
}
