import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/story.dart';
import '../format/diary_format.dart';
import 'entry_media_view.dart';
import 'entry_meta.dart';
import 'story_avatar.dart';

/// 피드 카드 ⋮ 의 동작. 화면이 `entry_actions` 로 잇는다.
enum FeedEntryAction { edit, move, trash }

/// 피드(스펙 §3.1, 인스타 홈): 기록마다 카드. 머리는 스토리 표지 작은 원 · 스토리 이름 · 장소 · ⋮,
/// 미디어는 4:5 칸에서 좌우로 넘기고(`1/n`), 영상은 썸네일 + ▶ 로만 둔다(재생은 뷰어에서).
/// 긴 본문은 [FeedView.foldedLines] 줄로 접는다. [header] 는 첫 칸으로 함께 스크롤한다.
class FeedView extends StatelessWidget {
  const FeedView({
    required this.entries,
    required this.now,
    required this.stories,
    required this.onOpen,
    this.covers = const {},
    this.onOpenStory,
    this.onTag,
    this.onAction,
    this.header,
    super.key,
  });

  /// 접힌 본문의 줄 수.
  static const foldedLines = 3;

  /// 최신순.
  final List<DiaryEntry> entries;
  final DateTime now;

  /// 스토리 id → 스토리. 없는 스토리면 머리에 장소만 둔다.
  final Map<String, Story> stories;

  /// 스토리 id → 표지 사진 파일. 없으면 이니셜.
  final Map<String, File?> covers;

  /// 카드 몸통(미디어 · 글)을 눌렀다.
  final ValueChanged<DiaryEntry> onOpen;

  /// 카드 머리를 눌렀다. null 이면 머리를 누를 수 없다.
  final ValueChanged<Story>? onOpenStory;

  /// 태그 칩을 눌렀다. null 이면 칩을 누를 수 없다.
  final ValueChanged<String>? onTag;

  /// 카드 ⋮ 를 골랐다. null 이면 ⋮ 를 두지 않는다.
  final void Function(DiaryEntry entry, FeedEntryAction action)? onAction;

  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final offset = header == null ? 0 : 1;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      itemCount: entries.length + offset,
      itemBuilder: (context, i) {
        if (header != null && i == 0) return header;
        final entry = entries[i - offset];
        final story = stories[entry.storyId];
        final onOpenStory = this.onOpenStory;
        final onAction = this.onAction;
        return _FeedCard(
          key: ValueKey(entry.id),
          entry: entry,
          now: now,
          story: story,
          cover: covers[entry.storyId],
          onTap: () => onOpen(entry),
          onStory: story == null || onOpenStory == null
              ? null
              : () => onOpenStory(story),
          onTag: onTag,
          onAction: onAction == null ? null : (a) => onAction(entry, a),
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.entry,
    required this.now,
    required this.story,
    required this.cover,
    required this.onTap,
    required this.onStory,
    required this.onTag,
    required this.onAction,
    super.key,
  });

  /// 미디어 칸의 가로세로 비(인스타 세로 사진).
  static const _aspect = 4 / 5;

  final DiaryEntry entry;
  final DateTime now;
  final Story? story;
  final File? cover;
  final VoidCallback onTap;
  final VoidCallback? onStory;
  final ValueChanged<String>? onTag;
  final ValueChanged<FeedEntryAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final media = entry.media;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHead(
            entry: entry,
            story: story,
            cover: cover,
            onTap: onStory,
            onAction: onAction,
          ),
          InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (media.isNotEmpty)
                  AspectRatio(
                    aspectRatio: _aspect,
                    child: MediaPager(media: media),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.body.isNotEmpty) ...[
                        _FoldedBody(text: entry.body),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (entry.tags.isNotEmpty) ...[
                        EntryTags(tags: entry.tags, onTap: onTag),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        DiaryFormat.relative(l10n, entry.occurredAt, now),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드 머리: 표지 작은 원 · 스토리 이름 · 장소(누르면 스토리 페이지) + ⋮.
class _CardHead extends StatelessWidget {
  const _CardHead({
    required this.entry,
    required this.story,
    required this.cover,
    required this.onTap,
    required this.onAction,
  });

  /// 머리 표지 원 반지름. 시각 토큰이 아니라 이 위젯의 크기다.
  static const _radius = 16.0;

  final DiaryEntry entry;
  final Story? story;
  final File? cover;
  final VoidCallback? onTap;
  final ValueChanged<FeedEntryAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final story = this.story;
    final title = story == null ? null : storyDisplayTitle(l10n, story);
    final place = entry.location?.placeName;
    final onAction = this.onAction;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  if (title != null) ...[
                    StoryCoverCircle(
                      label: title,
                      image: cover,
                      radius: _radius,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        if (place != null && place.isNotEmpty)
                          Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onAction != null)
          AppOverflowMenu<FeedEntryAction>(
            items: [
              AppOverflowMenuItem(
                value: FeedEntryAction.edit,
                label: l10n.walkDiaryEntryEdit,
                icon: Icons.edit_outlined,
              ),
              AppOverflowMenuItem(
                value: FeedEntryAction.move,
                label: l10n.walkDiaryEntryMove,
                icon: Icons.drive_file_move_outline,
              ),
              AppOverflowMenuItem(
                value: FeedEntryAction.trash,
                label: l10n.walkDiaryEntryTrash,
                icon: Icons.delete_outline,
                isDestructive: true,
              ),
            ],
            onSelected: onAction,
          ),
      ],
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
