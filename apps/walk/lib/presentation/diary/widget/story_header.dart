import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_view_mode.dart';
import '../../../domain/diary/entity/story.dart';
import '../format/diary_format.dart';
import 'story_bar.dart';
import 'view_mode_switch.dart';

/// 기록 목록 위 머리(스펙 §6.1): `제주 여행 · 10월 7일 ~ 진행 중` + 보기 모드 토글.
/// [story] 가 null 이면 '전체' — 기간 없이 이름만.
class StoryHeader extends StatelessWidget {
  const StoryHeader({
    required this.story,
    required this.now,
    required this.mode,
    required this.onMode,
    super.key,
  });

  final Story? story;
  final DateTime now;
  final DiaryViewMode mode;
  final ValueChanged<DiaryViewMode> onMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final story = this.story;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: story == null
                      ? l10n.walkDiaryAll
                      : storyDisplayTitle(l10n, story),
                  style: theme.textTheme.titleMedium,
                ),
                if (story != null)
                  TextSpan(
                    text: ' · ${DiaryFormat.storyPeriod(l10n, story, now)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          ViewModeSwitch(mode: mode, onChanged: onMode),
        ],
      ),
    );
  }
}
