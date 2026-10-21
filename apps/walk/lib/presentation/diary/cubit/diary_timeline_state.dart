import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/story.dart';

part 'diary_timeline_state.freezed.dart';

/// 일기 탭(스펙 §3.1): 동그라미 줄의 스토리 + 모든 스토리 기록 피드.
/// 스토리는 `StoryOrder.split` 순서 그대로.
@freezed
class DiaryTimelineState with _$DiaryTimelineState {
  /// 열린 스토리(기본 스토리 포함), lastPostedAt 최신순.
  @override
  final List<Story> openStories;

  /// 닫힌 스토리(보관함), endedAt 최신순.
  @override
  final List<Story> archived;

  /// 모든 스토리의 기록(휴지통 제외), 최신순.
  @override
  final List<DiaryEntry> entries;

  /// 첫 기록 목록을 아직 받지 못했다.
  @override
  final bool loading;

  /// 스토리 · 기록 목록을 읽지 못했다.
  @override
  final bool failed;

  const DiaryTimelineState({
    this.openStories = const [],
    this.archived = const [],
    this.entries = const [],
    this.loading = true,
    this.failed = false,
  });
}
