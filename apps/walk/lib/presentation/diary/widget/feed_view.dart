import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/story.dart';
import '../format/diary_format.dart';
import 'entry_media_view.dart';
import 'entry_meta.dart';
import 'story_avatar.dart';
import '../../common/row_actions_sheet.dart';

/// 피드 카드 동작(머리의 고치기 아이콘 · 길게 누르기 시트). 화면이 `entry_actions` 로 잇는다.
enum FeedEntryAction { edit, move, trash }

/// 피드(스펙 2026-11-15 §F5, 일반 피드식): 기록마다 카드. 머리는 날짜 · 시각 + 장소, 스토리 이름은
/// '일상'이 아닐 때만 작은 글씨로(누르면 [onOpenStory]) · 고치기 아이콘. 카드를 길게 누르면
/// 고치기 · 스토리 옮기기 · 휴지통 시트다 — 앱바 ⋮(화면 전체 동작)와 카드 ⋮ 가 겹치지 않게
/// 카드에는 ⋮ 를 두지 않는다. 미디어는 4:5 칸에서 좌우로 넘기고
/// (`1/n`), 영상은 썸네일 + ▶ 로만 둔다. **미디어를 누르면** [onOpen](그 기록을 전체 화면으로).
/// 글은 눌러도 열리지 않고, 긴 글은 [FeedView.foldedLines] 줄로 접어 "더 보기"로 펼친다.
/// [header] 는 첫 칸으로 함께 스크롤한다.
class FeedView extends StatelessWidget {
  const FeedView({
    required this.entries,
    required this.now,
    required this.stories,
    required this.onOpen,
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

  /// 스토리 id → 스토리. 없는 스토리면 머리에 스토리 이름을 두지 않는다.
  final Map<String, Story> stories;

  /// 카드의 미디어를 눌렀다.
  final ValueChanged<DiaryEntry> onOpen;

  /// 머리의 스토리 이름을 눌렀다. null 이면 누를 수 없다.
  final ValueChanged<Story>? onOpenStory;

  /// 태그 칩을 눌렀다. null 이면 칩을 누를 수 없다.
  final ValueChanged<String>? onTag;

  /// 카드 동작을 골랐다. null 이면 고치기 아이콘 · 길게 누르기 시트를 두지 않는다.
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
          onOpenMedia: () => onOpen(entry),
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
    required this.onOpenMedia,
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
  final VoidCallback onOpenMedia;
  final VoidCallback? onStory;
  final ValueChanged<String>? onTag;
  final ValueChanged<FeedEntryAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final media = entry.media;
    final onAction = this.onAction;
    final card = Card(
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
            now: now,
            story: story,
            onStory: onStory,
            onAction: onAction,
          ),
          if (media.isNotEmpty)
            InkWell(
              onTap: onOpenMedia,
              child: AspectRatio(
                aspectRatio: _aspect,
                child: MediaPager(media: media),
              ),
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
                  if (entry.tags.isNotEmpty)
                    EntryTags(tags: entry.tags, onTap: onTag),
                ],
              ),
            ),
        ],
      ),
    );
    if (onAction == null) return card;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      onLongPressHint: l10n.walkDiaryEntryActionsHint,
      child: GestureDetector(
        onLongPress: () => _openActions(context, onAction),
        child: card,
      ),
    );
  }

  /// 길게 누르기 시트 — 제목은 카드 머리의 날짜 · 시각, 휴지통은 error 색.
  Future<void> _openActions(
    BuildContext context,
    ValueChanged<FeedEntryAction> onAction,
  ) async {
    final l10n = AppLocalizations.of(context);
    final action = await showRowActions<FeedEntryAction>(
      context,
      title: _when(context, entry, now),
      actions: [
        RowAction(
          key: const Key('feed-action-edit'),
          value: FeedEntryAction.edit,
          label: l10n.walkDiaryEntryEdit,
          icon: Icons.edit_outlined,
        ),
        RowAction(
          key: const Key('feed-action-move'),
          value: FeedEntryAction.move,
          label: l10n.walkDiaryEntryMove,
          icon: Icons.drive_file_move_outline,
        ),
        RowAction(
          key: const Key('feed-action-trash'),
          value: FeedEntryAction.trash,
          label: l10n.walkDiaryEntryTrash,
          icon: Icons.delete_outline,
          isDestructive: true,
        ),
      ],
    );
    if (action != null) onAction(action);
  }
}

/// 카드 머리 · 동작 시트 제목의 '오늘 · 오후 3:00'.
String _when(BuildContext context, DiaryEntry entry, DateTime now) {
  final l10n = AppLocalizations.of(context);
  final at = entry.occurredAt;
  return '${DiaryFormat.dayHeader(l10n, at, now)} · ${DiaryFormat.time(context, at)}';
}

/// 카드 머리: 날짜 · 시각, 아래 장소 · 스토리 이름('일상'이 아닐 때, 누르면 [onStory]) + 고치기.
class _CardHead extends StatelessWidget {
  const _CardHead({
    required this.entry,
    required this.now,
    required this.story,
    required this.onStory,
    required this.onAction,
  });

  final DiaryEntry entry;
  final DateTime now;
  final Story? story;
  final VoidCallback? onStory;
  final ValueChanged<FeedEntryAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final story = this.story;
    final storyTitle = story == null || story.id == Story.dailyId
        ? null
        : storyDisplayTitle(l10n, story);
    final place = entry.location?.placeName;
    final when = _when(context, entry, now);
    final small = theme.textTheme.labelSmall;
    final onAction = this.onAction;
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if ((place != null && place.isNotEmpty) || storyTitle != null)
                  Row(
                    children: [
                      if (place != null && place.isNotEmpty)
                        Flexible(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (place != null &&
                          place.isNotEmpty &&
                          storyTitle != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (storyTitle != null)
                        Flexible(
                          child: InkWell(
                            onTap: onStory,
                            child: Text(
                              storyTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: small?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (onAction != null)
          IconButton(
            key: const Key('feed-edit'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.walkDiaryEntryEdit,
            onPressed: () => onAction(FeedEntryAction.edit),
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
