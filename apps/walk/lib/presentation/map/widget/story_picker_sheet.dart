import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../diary/widget/story_avatar.dart';

/// 스토리 고르기 시트를 띄운다. 고르지 않고 닫으면 null.
Future<Story?> showStoryPicker(BuildContext context) =>
    showModalBottomSheet<Story>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
class StoryPickerSheet extends StatefulWidget {
  const StoryPickerSheet({super.key});

  @override
  State<StoryPickerSheet> createState() => _StoryPickerSheetState();
}

class _StoryPickerSheetState extends State<StoryPickerSheet> {
  late final _stories = getIt<DiaryRepository>().watchStories();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(l10n.localeName);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, controller) => StreamBuilder<List<Story>>(
        stream: _stories,
        builder: (context, snapshot) {
          final stories = pickableStories(snapshot.data ?? const []);
          return ListView(
            controller: controller,
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  l10n.walkMapStoryPickerTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (snapshot.hasData && stories.isEmpty)
                AppPlaceholder(message: l10n.walkMapStoryPickerEmpty),
              for (final story in stories)
                AppListTile(
                  title: Text(storyDisplayTitle(l10n, story)),
                  subtitle: Text(
                    [
                      date.format(story.startedAt.toLocal()),
                      if (story.endedAt case final end?)
                        date.format(end.toLocal()),
                    ].join(' – '),
                  ),
                  trailing: story.isOpen ? Text(l10n.walkMapStoryOpen) : null,
                  onTap: () => Navigator.of(context).pop(story),
                ),
            ],
          );
        },
      ),
    );
  }
}
