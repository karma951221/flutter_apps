import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/story.dart';
import 'story_avatar.dart';
import 'story_ring.dart';

/// 일기 탭 위 스토리 동그라미 줄(스펙 §3.1): `＋ 새 스토리` → 스토리들 → `모두 보기`.
/// 순서는 [ringOrder]. [selectedId] 는 작성 화면에서 고른 스토리 체크용.
class StoryRingRow extends StatelessWidget {
  const StoryRingRow({
    required this.open,
    required this.archived,
    required this.covers,
    required this.onCreate,
    required this.onOpen,
    required this.onLongPress,
    required this.onSeeAll,
    this.selectedId,
    this.showSeeAll = true,
    super.key,
  });

  final List<Story> open;
  final List<Story> archived;

  /// 스토리 id → 표지 사진 파일. 없으면 이니셜.
  final Map<String, File?> covers;
  final VoidCallback onCreate;
  final ValueChanged<Story> onOpen;
  final ValueChanged<Story> onLongPress;
  final VoidCallback onSeeAll;
  final String? selectedId;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stories = ringOrder(open, archived);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionCircle(
            label: l10n.walkDiaryStoryNew,
            icon: Icons.add,
            onTap: onCreate,
          ),
          for (final story in stories)
            StoryRing(
              story: story,
              cover: covers[story.id],
              selected: story.id == selectedId,
              onTap: () => onOpen(story),
              onLongPress: () => onLongPress(story),
            ),
          if (showSeeAll)
            _ActionCircle(
              label: l10n.walkDiarySeeAll,
              icon: Icons.chevron_right,
              onTap: onSeeAll,
            ),
        ],
      ),
    );
  }
}

/// 줄 양 끝의 아이콘 원(＋ · 모두 보기).
class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: SizedBox(
          width: StoryRing.defaultSize + AppSpacing.md,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 링 있는 칸과 같은 지름(링 + 틈을 뺀 원 반지름 + 테두리).
                SizedBox(
                  width: StoryRing.defaultSize,
                  height: StoryRing.defaultSize,
                  child: StoryCoverCircle(
                    label: label,
                    icon: icon,
                    radius: StoryRing.defaultSize / 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
