import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/story.dart';
import 'story_avatar.dart';
import 'story_bar.dart';

/// 줄에 보일 스토리 순서: 진행 중(기록 있는 것 `lastPostedAt` 최신순, 없는 것 뒤) +
/// 닫힘(`endedAt` 최신순, 최대 [maxClosed]).
List<Story> ringOrder(
  List<Story> open,
  List<Story> archived, {
  int maxClosed = 10,
}) {
  final posted = open.where((s) => s.lastPostedAt != null).toList()
    ..sort((a, b) => b.lastPostedAt!.compareTo(a.lastPostedAt!));
  final unposted = open.where((s) => s.lastPostedAt == null);
  final closed = archived.toList()
    ..sort(
      (a, b) => (b.endedAt ?? b.createdAt).compareTo(a.endedAt ?? a.createdAt),
    );
  return [...posted, ...unposted, ...closed.take(maxClosed)];
}

/// 인스타식 스토리 동그라미: 링 + 표지 원 + 한 줄 이름. 진행 중은 primary 링,
/// 닫힘은 outlineVariant 링. [selected] 면 원 위에 체크를 얹는다(작성 화면).
class StoryRing extends StatelessWidget {
  const StoryRing({
    required this.story,
    required this.onTap,
    this.cover,
    this.onLongPress,
    this.selected = false,
    this.size = defaultSize,
    super.key,
  });

  /// 칸 너비 · 원 지름. 시각 토큰이 아니라 이 위젯의 크기다.
  static const defaultSize = 64.0;
  static const _ring = 2.5;
  static const _gap = 2.0;

  /// 테스트가 링을 찾는 키.
  static const ringKey = ValueKey('story-ring');

  final Story story;
  final File? cover;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = storyDisplayTitle(AppLocalizations.of(context), story);
    final inner = size - 2 * (_ring + _gap);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.smAll,
        child: SizedBox(
          width: size + AppSpacing.md,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DecoratedBox(
                      key: ringKey,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: story.isOpen
                              ? colors.primary
                              : colors.outlineVariant,
                          width: _ring,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(_gap),
                        child: StoryCoverCircle(
                          label: label,
                          image: cover,
                          radius: inner / 2,
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: AppSpacing.md,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          child: const Icon(Icons.check, size: AppSpacing.md),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? colors.primary : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
