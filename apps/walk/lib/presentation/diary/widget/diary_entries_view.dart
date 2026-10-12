import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/diary_view_mode.dart';
import 'entry_media_view.dart';
import 'feed_view.dart';
import 'prose_view.dart';
import 'reels_view.dart';

/// 기록 목록을 [mode] 에 맞는 보기(줄글 · 피드 · 릴스)로 그린다(스펙 §6.1).
class DiaryEntriesView extends StatelessWidget {
  const DiaryEntriesView({
    required this.mode,
    required this.entries,
    required this.showStoryName,
    required this.storyTitles,
    required this.onOpen,
    this.videoBuilder = videoSurface,
    super.key,
  });

  final DiaryViewMode mode;

  /// 최신순.
  final List<DiaryEntry> entries;

  /// '전체'를 볼 때만 true — 기록마다 스토리 이름을 붙인다.
  final bool showStoryName;

  /// 스토리 id → 표시 이름.
  final Map<String, String> storyTitles;

  final ValueChanged<DiaryEntry> onOpen;

  /// 릴스의 영상 재생 자리. 테스트는 가짜를 넣는다.
  final VideoSurfaceBuilder videoBuilder;

  @override
  Widget build(BuildContext context) {
    final now = getIt<Clock>().now();
    String? storyNameOf(DiaryEntry e) =>
        showStoryName ? storyTitles[e.storyId] : null;
    return switch (mode) {
      DiaryViewMode.prose => ProseView(
        entries: entries,
        now: now,
        storyNameOf: storyNameOf,
        onOpen: onOpen,
      ),
      DiaryViewMode.feed => FeedView(
        entries: entries,
        now: now,
        storyNameOf: storyNameOf,
        onOpen: onOpen,
      ),
      DiaryViewMode.reels => ReelsView(
        entries: entries,
        now: now,
        storyNameOf: storyNameOf,
        onOpen: onOpen,
        videoBuilder: videoBuilder,
      ),
    };
  }
}
