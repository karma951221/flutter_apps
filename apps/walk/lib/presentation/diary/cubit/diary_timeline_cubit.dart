import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/story_order.dart';
import 'diary_timeline_state.dart';

/// 일기 탭(스펙 §3.1): 스토리(동그라미 줄) + 모든 스토리의 기록(피드). 기록 저장 · 삭제 ·
/// 복원은 저장소 스트림으로 들어오므로 따로 새로고침하지 않는다.
class DiaryTimelineCubit extends Cubit<DiaryTimelineState> {
  DiaryTimelineCubit(this._repo) : super(const DiaryTimelineState());

  final DiaryRepository _repo;

  StreamSubscription<List<Story>>? _stories;
  StreamSubscription<List<DiaryEntry>>? _entries;

  /// 스토리와 모든 기록을 구독한다.
  void start() {
    unawaited(_stories?.cancel());
    unawaited(_entries?.cancel());
    emit(state.copyWith(loading: true, failed: false));
    _stories = _repo.watchStories().listen((stories) {
      final split = StoryOrder.split(stories);
      emit(state.copyWith(openStories: split.open, archived: split.archived));
    }, onError: _onError);
    _entries = _repo
        .watchEntries(const EntryFilter.all())
        .listen(
          (entries) => emit(state.copyWith(entries: entries, loading: false)),
          onError: _onError,
        );
  }

  void _onError(Object _) => emit(state.copyWith(loading: false, failed: true));

  @override
  Future<void> close() async {
    await _stories?.cancel();
    await _entries?.cancel();
    return super.close();
  }
}
