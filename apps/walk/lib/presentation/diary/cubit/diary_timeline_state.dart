import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/diary_view_mode.dart';
import '../../../domain/diary/entity/story.dart';

part 'diary_timeline_state.freezed.dart';

/// 일기 타임라인(스펙 §6.1). 스토리는 `StoryOrder.split` 순서 그대로.
@freezed
class DiaryTimelineState with _$DiaryTimelineState {
  /// 열린 스토리(기본 스토리 포함), lastPostedAt 최신순.
  @override
  final List<Story> openStories;

  /// 닫힌 스토리(보관함), endedAt 최신순.
  @override
  final List<Story> archived;

  /// 보고 있는 스토리. null 이면 '전체'.
  @override
  final String? selectedStoryId;

  @override
  final DiaryViewMode viewMode;

  /// [selectedStoryId] 의 기록(휴지통 제외), 최신순.
  @override
  final List<DiaryEntry> entries;

  /// 지금 고른 필터의 첫 기록 목록을 아직 받지 못했다.
  @override
  final bool loading;

  /// 스토리 · 기록 목록을 읽지 못했다. 다른 스토리를 고르면 다시 시도한다.
  @override
  final bool failed;

  const DiaryTimelineState({
    this.openStories = const [],
    this.archived = const [],
    this.selectedStoryId,
    this.viewMode = DiaryViewMode.prose,
    this.entries = const [],
    this.loading = true,
    this.failed = false,
  });
}
