import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/classify/story_pick.dart';
import '../../../domain/diary/entity/story.dart';
import 'story_avatar.dart';

part 'story_suggestion_sheet.freezed.dart';

/// [StorySuggestionSheet] 에서 고른 것. 시트를 내리면 null(작성 화면에 머문다).
@freezed
sealed class StorySuggestionChoice with _$StorySuggestionChoice {
  /// 기존 스토리 [storyId] 로 저장한다.
  const factory StorySuggestionChoice.accept(String storyId) =
      StorySuggestionAccept;

  /// 이름이 [title] 인 새 스토리를 만들어 저장한다.
  const factory StorySuggestionChoice.create(String title) =
      StorySuggestionCreate;

  /// 스토리 고르기 시트로 다른 스토리를 고른다.
  const factory StorySuggestionChoice.other() = StorySuggestionOther;
}

/// 올리기를 누른 뒤 AI 가 고른 스토리를 보인다(스펙 2026-11-19).
/// 한 번 누르면 받아들여 저장하고, 새 스토리면 이름을 고칠 수 있다.
class StorySuggestionSheet extends StatefulWidget {
  const StorySuggestionSheet({
    required this.pick,
    required this.stories,
    super.key,
  });

  /// [StoryPickExisting] 또는 [StoryPickCreate].
  final StoryPick pick;

  /// 이름을 찾을 스토리 목록.
  final List<Story> stories;

  static Future<StorySuggestionChoice?> show(
    BuildContext context, {
    required StoryPick pick,
    required List<Story> stories,
  }) => showModalBottomSheet<StorySuggestionChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => StorySuggestionSheet(pick: pick, stories: stories),
  );

  @override
  State<StorySuggestionSheet> createState() => _StorySuggestionSheetState();
}

class _StorySuggestionSheetState extends State<StorySuggestionSheet> {
  late final _title = TextEditingController(
    text: switch (widget.pick) {
      StoryPickCreate(:final title) => title,
      _ => '',
    },
  );

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pick = widget.pick;
    final reason = switch (pick) {
      StoryPickExisting(:final reason) ||
      StoryPickCreate(:final reason) => reason,
      StoryPickFallback() => '',
    };
    final story = switch (pick) {
      StoryPickExisting(:final storyId) =>
        widget.stories.where((s) => s.id == storyId).firstOrNull,
      _ => null,
    };
    final isNew = pick is StoryPickCreate;
    final canAccept = !isNew || _title.text.trim().isNotEmpty;

    void accept() {
      if (!canAccept) return;
      Navigator.of(context).pop(switch (pick) {
        StoryPickExisting(:final storyId) => StorySuggestionChoice.accept(
          storyId,
        ),
        _ => StorySuggestionChoice.create(_title.text.trim()),
      });
    }

    return Padding(
      // 새 스토리 이름을 고칠 때 키보드에 가리지 않게.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.walkDiaryStoryAiTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (isNew) ...[
                Text(
                  l10n.walkDiaryStoryAiNewLabel,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  key: const Key('story-ai-new-title'),
                  controller: _title,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: l10n.walkDiaryStoryAiNewHint,
                    prefixIcon: const Icon(Icons.add),
                  ),
                  onSubmitted: (_) => accept(),
                ),
              ] else
                AppListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text(
                    story == null ? '' : storyDisplayTitle(l10n, story),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: AppSpacing.md,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        reason,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                key: const Key('story-ai-accept'),
                label: isNew
                    ? l10n.walkDiaryStoryAiCreateAccept
                    : l10n.walkDiaryStoryAiAccept,
                onPressed: canAccept ? accept : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                key: const Key('story-ai-other'),
                label: l10n.walkDiaryStoryAiOther,
                onPressed: () => Navigator.of(
                  context,
                ).pop(const StorySuggestionChoice.other()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
