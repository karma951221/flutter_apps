import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/media/media_store.dart';
import '../../../domain/diary/usecase/story_cover.dart';
import '../format/diary_format.dart';
import '../widget/entry_media_view.dart';
import '../widget/entry_meta.dart';
import '../widget/story_avatar.dart';
import '../widget/story_bar.dart';
import 'story_progress_bar.dart';
import 'viewer_model.dart';

/// 뷰어가 영상 자리에 넘기는 것: 파일 · 재생 여부 · 준비/끝/실패 알림.
class ViewerVideo {
  const ViewerVideo({
    required this.file,
    required this.playing,
    required this.onReady,
    required this.onEnded,
    required this.onFailed,
  });

  final File file;
  final bool playing;
  final ValueChanged<Duration> onReady;
  final VoidCallback onEnded;
  final VoidCallback onFailed;
}

/// 뷰어의 영상 자리. 테스트는 `video_player` 대신 가짜를 넣는다.
typedef ViewerVideoBuilder =
    Widget Function(BuildContext context, ViewerVideo video);

/// 기본 영상 자리 — 한 번만 재생하는 [VideoSurface].
Widget viewerVideoSurface(BuildContext context, ViewerVideo video) =>
    VideoSurface(
      file: video.file,
      loop: false,
      playing: video.playing,
      onReady: video.onReady,
      onEnded: video.onEnded,
      onFailed: video.onFailed,
    );

/// 뷰어 조각 하나의 몸통: 사진 · 영상(contain) 또는 글 카드(글 전체를 가운데 크게).
/// [active] 가 아니면(넘겨 보이는 옆 그룹) 영상은 썸네일만 그린다.
class ViewerSlideView extends StatelessWidget {
  const ViewerSlideView({
    required this.slide,
    required this.active,
    required this.video,
    this.videoBuilder = viewerVideoSurface,
    super.key,
  });

  final ViewerSlide slide;
  final bool active;

  /// [active] 인 영상 조각에만 쓴다.
  final ViewerVideo Function(File file) video;
  final ViewerVideoBuilder videoBuilder;

  @override
  Widget build(BuildContext context) {
    final media = slide.media;
    if (media == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            slide.entry.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      );
    }
    if (active && media.kind == MediaKind.video) {
      return videoBuilder(
        context,
        video(getIt<MediaStore>().resolve(media.path)),
      );
    }
    return EntryMediaView(media: media, fit: BoxFit.contain);
  }
}

/// 조각 아래 그늘 위 글: 장소 · 시각, 글 3줄(탭하면 펼침), 태그.
/// 글 조각은 글이 가운데 크게 있으므로 여기서는 글을 빼고 장소 · 시각 · 태그만 둔다.
class ViewerCaption extends StatelessWidget {
  const ViewerCaption({
    required this.slide,
    required this.expanded,
    required this.onToggle,
    super.key,
  });

  final ViewerSlide slide;
  final bool expanded;
  final VoidCallback onToggle;

  /// 미디어 위 글 뒤 그늘의 불투명도 — 릴스와 같다.
  static const _scrimAlpha = 0.7;

  /// 접힌 글의 줄 수.
  static const _lines = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scrim = theme.colorScheme.scrim;
    final entry = slide.entry;
    final place = entry.location?.placeName;
    final time = DiaryFormat.time(context, entry.occurredAt);
    final meta = place == null || place.isEmpty
        ? time
        : '${l10n.walkDiaryPlace(place)} · $time';
    final showBody = slide.media != null && entry.body.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacing.xl,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scrim.withValues(alpha: 0),
                  scrim.withValues(alpha: _scrimAlpha),
                ],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scrim.withValues(alpha: _scrimAlpha),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (showBody) ...[
                    const SizedBox(height: AppSpacing.xs),
                    GestureDetector(
                      onTap: onToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        entry.body,
                        style: theme.textTheme.bodyLarge,
                        maxLines: expanded ? null : _lines,
                        overflow: expanded ? null : TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    EntryTags(tags: entry.tags),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 뷰어 조각의 ⋮ 동작.
enum ViewerEntryAction { edit, move, trash }

/// 뷰어 머리: 그날 진행 막대, 표지 원 · 그룹 이름 · `n일차 · 날짜`(일차는 스토리만), ⋮ · ✕.
class ViewerHeader extends StatelessWidget {
  const ViewerHeader({
    required this.group,
    required this.day,
    required this.index,
    required this.progress,
    required this.onAction,
    required this.onClose,
    this.icon,
    super.key,
  });

  final ViewerGroup group;
  final ViewerDay day;

  /// 그날 안 지금 조각.
  final int index;
  final Animation<double> progress;
  final ValueChanged<ViewerEntryAction> onAction;
  final VoidCallback onClose;

  /// 모아보기 그룹의 표지 아이콘(태그 · 장소). 스토리는 null(표지 사진 · 이니셜).
  final IconData? icon;

  /// 표지 원 반지름. 시각 토큰이 아니라 이 위젯의 크기다.
  static const _avatarRadius = 16.0;

  /// 머리 뒤 그늘의 불투명도.
  static const _scrimAlpha = 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final story = group.story;
    final title = story == null ? group.title : storyDisplayTitle(l10n, story);
    final date = DiaryFormat.dateWithWeekday(
      l10n,
      day.date,
      getIt<Clock>().now(),
    );
    final n = dayNumber(group, day);
    final label = n == null ? date : '${l10n.walkDiaryDayNumber(n)} · $date';
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.scrim.withValues(alpha: _scrimAlpha),
            colors.scrim.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            0,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: StoryProgressBar(
                  count: day.slides.length,
                  index: index,
                  progress: progress,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  StoryCoverCircle(
                    label: title,
                    icon: icon,
                    image: story == null ? null : _cover(group, story),
                    radius: _avatarRadius,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  AppOverflowMenu<ViewerEntryAction>(
                    items: [
                      AppOverflowMenuItem(
                        value: ViewerEntryAction.edit,
                        label: l10n.walkDiaryEntryEdit,
                        icon: Icons.edit_outlined,
                      ),
                      AppOverflowMenuItem(
                        value: ViewerEntryAction.move,
                        label: l10n.walkDiaryEntryMove,
                        icon: Icons.drive_file_move_outline,
                      ),
                      AppOverflowMenuItem(
                        value: ViewerEntryAction.trash,
                        label: l10n.walkDiaryEntryTrash,
                        icon: Icons.delete_outline,
                        isDestructive: true,
                      ),
                    ],
                    onSelected: onAction,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.walkDiaryViewerClose,
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static File? _cover(ViewerGroup group, Story story) {
    final entries = {
      for (final d in group.days)
        for (final s in d.slides) s.entry.id: s.entry,
    }.values.toList();
    return coverFiles({
      story.id: StoryCoverRule.pick(story, entries),
    })[story.id];
  }
}
