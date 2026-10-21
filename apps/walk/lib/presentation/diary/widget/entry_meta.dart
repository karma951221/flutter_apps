import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../format/diary_format.dart';

/// 기록의 시각(· 스토리 이름)과 장소 줄. [storyName] 은 '전체'를 볼 때만 넘긴다.
class EntryMeta extends StatelessWidget {
  const EntryMeta({
    required this.entry,
    required this.now,
    this.storyName,
    super.key,
  });

  final DiaryEntry entry;
  final DateTime now;
  final String? storyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final stamp = DiaryFormat.stamp(context, entry.occurredAt, now);
    final story = storyName;
    final place = entry.location?.placeName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(story == null ? stamp : '$stamp · $story', style: style),
        if (place != null && place.isNotEmpty)
          Text(
            AppLocalizations.of(context).walkDiaryPlace(place),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// 기록의 해시태그 칩. 태그가 없으면 아무것도 그리지 않는다. [onTap] 이 있으면 칩을 누를 수 있다.
class EntryTags extends StatelessWidget {
  const EntryTags({required this.tags, this.onTap, super.key});

  final List<String> tags;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final onTap = this.onTap;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final tag in tags)
          if (onTap == null)
            Chip(
              label: Text(l10n.walkDiaryTag(tag)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            ActionChip(
              label: Text(l10n.walkDiaryTag(tag)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () => onTap(tag),
            ),
      ],
    );
  }
}
