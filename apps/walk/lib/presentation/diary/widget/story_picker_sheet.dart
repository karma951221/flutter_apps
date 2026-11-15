import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/story.dart';
import 'story_avatar.dart';

/// 스토리 고르기. 받은 스토리를 순서대로 보이고, 고르면 그 id 로 닫힌다.
/// [allowCreate] 면 맨 아래 '＋ 새 스토리' 항목을 두고, 누르면 [createNew] 로 닫힌다
/// (만들기는 부른 쪽이 한다).
class StoryPickerSheet extends StatelessWidget {
  const StoryPickerSheet({
    required this.stories,
    required this.selectedId,
    this.allowCreate = false,
    super.key,
  });

  /// 보일 스토리, 순서대로.
  final List<Story> stories;
  final String selectedId;
  final bool allowCreate;

  /// '＋ 새 스토리' 를 골랐을 때의 결과. 스토리 id(uuid · `daily`)와 겹치지 않는다.
  static const createNew = '+new';

  static Future<String?> show(
    BuildContext context, {
    required List<Story> stories,
    required String selectedId,
    bool allowCreate = false,
  }) => showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => StoryPickerSheet(
      stories: stories,
      selectedId: selectedId,
      allowCreate: allowCreate,
    ),
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
                if (allowCreate)
                  AppListTile(
                    leading: const Icon(Icons.add),
                    title: Text(l10n.walkDiaryStoryNew),
                    onTap: () => Navigator.of(context).pop(createNew),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
