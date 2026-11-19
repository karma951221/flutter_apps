import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../diary/widget/story_row.dart';

/// 스토리 고르기 시트를 띄운다. 고르지 않고 닫으면 null.
Future<Story?> showStoryPicker(BuildContext context) => showAppSheet<Story>(
  context: context,
  builder: (_) => const StoryPickerSheet(),
);

/// 진행 중인 스토리 먼저, 그 뒤 최근에 시작한 순. 기본 스토리(`daily`)는 뺀다.
List<Story> pickableStories(List<Story> stories) =>
    [
      for (final s in stories)
        if (!s.isDefault) s,
    ]..sort((a, b) {
      if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
      return b.startedAt.compareTo(a.startedAt);
    });

/// 지도 › 스토리 — 어떤 스토리 기간을 볼지 고른다. 고른 스토리로 `pop` 한다.
///
/// 행은 [StoryRow] — 표지(사진 · 이니셜) · 기간 · 기록 수를 보여 이름만으로 찾지 않게 한다.
/// 기록을 읽지 못하면 표지는 이니셜, 수는 뺀다. 진행 중이면 기간 끝이 '진행 중'이다.
class StoryPickerSheet extends StatefulWidget {
  const StoryPickerSheet({super.key});

  @override
  State<StoryPickerSheet> createState() => _StoryPickerSheetState();
}

class _StoryPickerSheetState extends State<StoryPickerSheet> {
  late final _repo = getIt<DiaryRepository>();
  late final _stories = _repo.watchStories();
  late final _entries = _repo.watchEntries(const EntryFilter.all());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = getIt<Clock>().now();
    return StreamBuilder<List<DiaryEntry>>(
      stream: _entries,
      builder: (context, entrySnap) => StreamBuilder<List<Story>>(
        stream: _stories,
        builder: (context, snapshot) {
          final stories = pickableStories(snapshot.data ?? const []);
          final data = storyRowData(stories, entrySnap.data);
          return AppSheetScaffold.draggable(
            title: l10n.walkMapStoryPickerTitle,
            maxSize: 0.9,
            children: [
              if (snapshot.hasData && stories.isEmpty)
                AppPlaceholder(
                  icon: Icons.auto_stories_outlined,
                  message: l10n.walkMapStoryPickerEmpty,
                ),
              for (final story in stories)
                StoryRow(
                  key: ValueKey('story-pick-${story.id}'),
                  story: story,
                  now: now,
                  cover: data.covers[story.id],
                  count: data.counts?[story.id],
                  onTap: () => Navigator.of(context).pop(story),
                ),
            ],
          );
        },
      ),
    );
  }
}
