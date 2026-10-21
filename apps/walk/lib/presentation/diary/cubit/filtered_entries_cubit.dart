import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import 'filtered_entries_state.dart';

/// 태그 · 장소 모아보기 공통 — [filter] 의 기록을 구독한다. 기록 추가 · 휴지통 · 복원은
/// 저장소 스트림으로 바로 들어온다.
class FilteredEntriesCubit extends Cubit<FilteredEntriesState> {
  FilteredEntriesCubit(this._repo, this.filter)
    : super(const FilteredEntriesState());

  final DiaryRepository _repo;
  final EntryFilter filter;

  StreamSubscription<List<DiaryEntry>>? _entries;
  StreamSubscription<List<Story>>? _stories;

  void start() {
    unawaited(_entries?.cancel());
    unawaited(_stories?.cancel());
    _entries = _repo
        .watchEntries(filter)
        .listen(
          (entries) => emit(state.copyWith(entries: entries, loading: false)),
          onError: _onError,
        );
    _stories = _repo.watchStories().listen(
      (stories) => emit(state.copyWith(stories: stories)),
      onError: _onError,
    );
  }

  void _onError(Object _) => emit(state.copyWith(loading: false, failed: true));

  @override
  Future<void> close() async {
    await _entries?.cancel();
    await _stories?.cancel();
    return super.close();
  }
}
