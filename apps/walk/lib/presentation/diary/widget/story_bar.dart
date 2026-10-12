import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/story.dart';
import 'story_avatar.dart';

/// 스토리의 표시 이름. 기본 스토리처럼 title 이 비면 l10n 기본 제목.
String storyDisplayTitle(AppLocalizations l10n, Story story) =>
    story.title.isEmpty ? l10n.walkDiaryDailyStoryTitle : story.title;

/// 일기 탭 위 스토리 바(스펙 §6.1): 전체 → [open](받은 순서 그대로) → 보관함.
/// 보관함은 닫힌 스토리가 있을 때만 두고, 누르면 그 목록 시트에서 고른다.
class StoryBar extends StatelessWidget {
  const StoryBar({
    required this.open,
    required this.archived,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  final List<Story> open;
  final List<Story> archived;

  /// null 이면 '전체'.
  final String? selectedId;

  /// 고른 스토리 id. '전체'는 null.
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewingArchived = archived.any((s) => s.id == selectedId);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          StoryAvatar(
            label: l10n.walkDiaryAll,
            icon: Icons.auto_stories_outlined,
            selected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          for (final story in open)
            StoryAvatar(
              label: storyDisplayTitle(l10n, story),
              selected: story.id == selectedId,
              onTap: () => onSelect(story.id),
            ),
          if (archived.isNotEmpty)
            StoryAvatar(
              label: l10n.walkDiaryArchive,
              icon: Icons.inventory_2_outlined,
              selected: viewingArchived,
              onTap: () => _openArchive(context),
            ),
        ],
      ),
    );
  }

  Future<void> _openArchive(BuildContext context) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ArchiveSheet(stories: archived, selectedId: selectedId),
    );
    if (id != null) onSelect(id);
  }
}

/// 닫힌 스토리 목록. 고르면 그 id 로 닫힌다.
class _ArchiveSheet extends StatelessWidget {
  const _ArchiveSheet({required this.stories, required this.selectedId});

  final List<Story> stories;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.walkDiaryArchive,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final story in stories)
                  AppListTile(
                    title: Text(storyDisplayTitle(l10n, story)),
                    trailing: story.id == selectedId
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(context).pop(story.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
