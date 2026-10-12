import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../format/diary_format.dart';
import 'entry_media_view.dart';
import 'entry_meta.dart';

/// 줄글: 날짜 머리 아래 그날 기록의 글이 이어지고, 미디어는 작은 썸네일 줄.
class ProseView extends StatelessWidget {
  const ProseView({
    required this.entries,
    required this.now,
    required this.storyNameOf,
    required this.onOpen,
    super.key,
  });

  /// 최신순.
  final List<DiaryEntry> entries;
  final DateTime now;
  final String? Function(DiaryEntry) storyNameOf;
  final ValueChanged<DiaryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // 날짜가 바뀌는 자리마다 머리를 끼운다.
    final rows = <Widget>[];
    for (final (i, entry) in entries.indexed) {
      if (i == 0 ||
          !DiaryFormat.sameDay(entries[i - 1].occurredAt, entry.occurredAt)) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? AppSpacing.sm : AppSpacing.lg,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              DiaryFormat.dayHeader(l10n, entry.occurredAt, now),
              style: theme.textTheme.titleSmall,
            ),
          ),
        );
      }
      rows.add(
        _ProseEntry(
          key: ValueKey(entry.id),
          entry: entry,
          now: now,
          storyName: storyNameOf(entry),
          onTap: () => onOpen(entry),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: rows.length,
      itemBuilder: (context, i) => rows[i],
    );
  }
}

class _ProseEntry extends StatelessWidget {
  const _ProseEntry({
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

  /// 썸네일 한 변. 시각 토큰이 아니라 이 줄의 크기다.
  static const _thumb = 64.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EntryMeta(entry: entry, now: now, storyName: storyName),
            if (entry.body.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(entry.body, style: theme.textTheme.bodyLarge),
            ],
            if (entry.media.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: _thumb,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.media.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: SizedBox.square(
                      dimension: _thumb,
                      child: EntryMediaView(media: entry.media[i]),
                    ),
                  ),
                ),
              ),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              EntryTags(tags: entry.tags),
            ],
          ],
        ),
      ),
    );
  }
}
