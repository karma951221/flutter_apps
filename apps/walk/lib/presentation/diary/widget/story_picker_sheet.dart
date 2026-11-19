import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/story.dart';
import 'story_row.dart';

/// 스토리 고르기. 받은 스토리를 순서대로 보이고, 고르면 그 id 로 닫힌다.
/// [allowCreate] 면 맨 아래 '＋ 새 스토리' 항목을 두고, 누르면 [createNew] 로 닫힌다
/// (만들기는 부른 쪽이 한다).
///
/// 행은 [StoryRow] — 지도의 스토리 고르기와 같은 모양이다. [entries] 를 주면 표지 · 기록
/// 수를 보이고, 없거나 아직 오지 않았으면 이니셜 표지 · 기간만 보인다.
class StoryPickerSheet extends StatelessWidget {
  const StoryPickerSheet({
    required this.stories,
    required this.selectedId,
    required this.now,
    this.entries,
    this.allowCreate = false,
    super.key,
  });

  /// 보일 스토리, 순서대로.
  final List<Story> stories;
  final String selectedId;

  /// 기간 표기의 기준 시각.
  final DateTime now;

  /// 표지 · 기록 수를 셀 기록(모든 스토리). 없으면 세지 않는다.
  final Stream<List<DiaryEntry>>? entries;
  final bool allowCreate;

  /// '＋ 새 스토리' 를 골랐을 때의 결과. 스토리 id(uuid · `daily`)와 겹치지 않는다.
  static const createNew = '+new';

  static Future<String?> show(
    BuildContext context, {
    required List<Story> stories,
    required String selectedId,
    required DateTime now,
    Stream<List<DiaryEntry>>? entries,
    bool allowCreate = false,
  }) => showAppSheet<String>(
    context: context,
    builder: (_) => StoryPickerSheet(
      stories: stories,
      selectedId: selectedId,
      now: now,
      entries: entries,
      allowCreate: allowCreate,
    ),
  );

  @override
  Widget build(BuildContext context) => StreamBuilder<List<DiaryEntry>>(
    stream: entries,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context);
      final data = storyRowData(stories, snapshot.data);
      return AppSheetScaffold(
        title: l10n.walkDiaryEditorPickStory,
        children: [
          for (final story in stories)
            StoryRow(
              story: story,
              now: now,
              cover: data.covers[story.id],
              count: data.counts?[story.id],
              selected: story.id == selectedId,
              onTap: () => Navigator.of(context).pop(story.id),
            ),
          if (allowCreate)
            AppListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.walkDiaryStoryNew),
              onTap: () => Navigator.of(context).pop(createNew),
            ),
        ],
      );
    },
  );
}
