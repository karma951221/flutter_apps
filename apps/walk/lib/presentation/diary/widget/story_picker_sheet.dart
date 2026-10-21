import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/story.dart';
import 'story_avatar.dart';

/// 작성 화면의 스토리 고르기. 받은 스토리(열린 것만 — `EntryEditorState.openStories`)를
/// 보이고, 고르면 그 id 로 닫힌다.
class StoryPickerSheet extends StatelessWidget {
  const StoryPickerSheet({
    required this.stories,
    required this.selectedId,
    super.key,
  });

  /// 열린 스토리, 보일 순서대로.
  final List<Story> stories;
  final String selectedId;

  static Future<String?> show(
    BuildContext context, {
    required List<Story> stories,
    required String selectedId,
  }) => showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => StoryPickerSheet(stories: stories, selectedId: selectedId),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.walkDiaryEditorPickStory,
              style: Theme.of(context).textTheme.titleLarge,
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
