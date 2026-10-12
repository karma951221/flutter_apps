import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/diary_view_mode.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/story_order.dart';
import 'diary_timeline_state.dart';

/// 일기 탭 타임라인: 스토리 바 + 고른 스토리의 기록. 기록 저장 · 삭제 · 복원은
/// 저장소 스트림으로 들어오므로 따로 새로고침하지 않는다.
class DiaryTimelineCubit extends Cubit<DiaryTimelineState> {
  DiaryTimelineCubit(this._repo, this._prefs)
    : super(const DiaryTimelineState());

  final DiaryRepository _repo;
  final DiaryPreferences _prefs;

  StreamSubscription<List<Story>>? _stories;
  StreamSubscription<List<DiaryEntry>>? _entries;

  /// 마지막으로 보던 스토리 · 보기 모드를 복원하고 스토리 · 기록을 구독한다.
  /// 그 스토리가 지워졌으면 스토리 목록이 도착할 때 '전체'로 바꾼다.
  void start() {
    emit(
      state.copyWith(
        selectedStoryId: _prefs.lastViewedStoryId,
        viewMode: _prefs.viewMode,
      ),
    );
    _watchEntries();
    unawaited(_stories?.cancel());
    _stories = _repo.watchStories().listen(_onStories);
  }

  /// [storyId] 가 null 이면 '전체'. 옛 필터의 구독을 끊어 늦게 온 목록이 섞이지 않는다.
  void selectStory(String? storyId) {
    unawaited(_prefs.setLastViewedStoryId(storyId));
    emit(state.copyWith(selectedStoryId: storyId));
    _watchEntries();
  }

  void setViewMode(DiaryViewMode m) {
    unawaited(_prefs.setViewMode(m));
    emit(state.copyWith(viewMode: m));
  }

  /// 보던 스토리가 사라졌으면(삭제 · 시작 때 이미 없음) '전체'로 바꾼다.
  void _onStories(List<Story> stories) {
    final split = StoryOrder.split(stories);
    emit(state.copyWith(openStories: split.open, archived: split.archived));
    final selected = state.selectedStoryId;
    if (selected != null && !stories.any((s) => s.id == selected)) {
      selectStory(null);
    }
  }

  void _watchEntries() {
    unawaited(_entries?.cancel());
    emit(state.copyWith(entries: const [], loading: true));
    final filter = switch (state.selectedStoryId) {
      null => const EntryFilter.all(),
      final id => EntryFilter.story(id),
    };
    _entries = _repo
        .watchEntries(filter)
        .listen(
          (entries) => emit(state.copyWith(entries: entries, loading: false)),
        );
  }

  @override
  Future<void> close() async {
    await _stories?.cancel();
    await _entries?.cancel();
    return super.close();
  }
}
