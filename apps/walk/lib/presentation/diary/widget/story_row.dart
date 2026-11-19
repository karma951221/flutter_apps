import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/usecase/story_cover.dart';
import '../format/diary_format.dart';
import 'story_avatar.dart';

/// 스토리 한 줄 — 표지 원 · 이름 · '기간 · 기록 n개'.
///
/// 스토리 고르기(일기 · 지도) · AI 추천 · 스토리 검색이 같은 모양으로 쓴다.
/// [selected] 가 있으면 고르기 행이다 — 고른 행에만 [AppSelectTile] 처럼 primary 체크.
/// 없으면 보통 목록 행이다.
class StoryRow extends StatelessWidget {
  const StoryRow({
    required this.story,
    required this.now,
    this.cover,
    this.count,
    this.selected,
    this.onTap,
    super.key,
  });

  final Story story;

  /// 기간 표기의 기준 시각(올해면 연도를 뺀다).
  final DateTime now;

  /// 표지 그림. 없으면 이름 첫 글자.
  final File? cover;

  /// 살아 있는 기록 수. 모르면 null — 부제에서 뺀다.
  final int? count;

  /// 고르기 행이면 고른 것인지. 보통 행이면 null.
  final bool? selected;
  final VoidCallback? onTap;

  /// 표지 원 반지름. 시각 토큰이 아니라 이 행의 크기다.
  static const coverRadius = 24.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = storyDisplayTitle(l10n, story);
    final count = this.count;
    final leading = StoryCoverCircle(
      label: title,
      image: cover,
      radius: coverRadius,
    );
    final subtitle = Text(
      [
        DiaryFormat.storyPeriod(l10n, story, now),
        if (count != null) l10n.walkDiaryEntryCount(count),
      ].join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final titleText = Text(title, maxLines: 1, overflow: TextOverflow.ellipsis);
    final selected = this.selected;
    if (selected != null) {
      return AppSelectTile(
        leading: leading,
        title: titleText,
        subtitle: subtitle,
        selected: selected,
        onTap: onTap,
      );
    }
    return AppListTile(
      leading: leading,
      title: titleText,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

/// 스토리 행에 필요한 표지 · 기록 수를 기록 목록에서 모은다.
///
/// [entries] 가 null 이면(아직 못 읽음 · 실패) 표지는 이니셜, 수는 모름(null)이다.
({Map<String, File> covers, Map<String, int>? counts}) storyRowData(
  List<Story> stories,
  List<DiaryEntry>? entries,
) {
  if (entries == null) return (covers: const {}, counts: null);
  final byStory = <String, List<DiaryEntry>>{};
  for (final e in entries) {
    if (!e.isTrashed) (byStory[e.storyId] ??= []).add(e);
  }
  return (
    covers: coverFiles({
      for (final s in stories)
        s.id: StoryCoverRule.pick(s, byStory[s.id] ?? const []),
    }),
    counts: {for (final s in stories) s.id: byStory[s.id]?.length ?? 0},
  );
}
