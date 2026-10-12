import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import 'diary_search_state.dart';

/// 일기 검색(스펙 §6.4). 입력은 [debounce] 뒤에, 탭 전환은 바로 조회한다.
///
/// 글 · 스토리는 빈(공백만 있는) 입력이면 조회하지 않는다. 해시태그 · 장소는 빈 입력이면
/// 상위 추천을 보인다. 결과는 저장소 스트림을 구독하므로 기록 추가 · 휴지통 · 복원이 바로
/// 반영되고, 입력 · 탭이 바뀌면 옛 구독을 끊어 늦은 응답이 섞이지 않는다.
class DiarySearchCubit extends Cubit<DiarySearchState> {
  DiarySearchCubit(
    this._repo, {
    required String dailyTitle,
    Duration debounce = const Duration(milliseconds: 300),
  }) : _dailyTitle = dailyTitle,
       _debounce = debounce,
       super(const DiarySearchState());

  final DiaryRepository _repo;

  /// 기본 스토리(제목이 빈 문자열로 저장돼 있다)를 찾을 이름.
  final String _dailyTitle;
  final Duration _debounce;

  Timer? _timer;
  StreamSubscription<Object?>? _sub;

  /// 같은 탭이면 아무것도 하지 않는다.
  void setScope(SearchScope s) {
    if (s == state.scope) return;
    emit(
      state.copyWith(
        scope: s,
        suggestions: const [],
        stories: const [],
        bodyResults: const [],
      ),
    );
    _search();
  }

  /// 같은 입력이면 아무것도 하지 않는다.
  void setQuery(String q) {
    if (q == state.query) return;
    emit(state.copyWith(query: q));
    _timer?.cancel();
    _timer = Timer(_debounce, _search);
  }

  void _search() {
    _timer?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
    final term = state.query.trim();
    final scope = state.scope;
    final needsInput = scope == SearchScope.body || scope == SearchScope.story;
    if (needsInput && term.isEmpty) {
      emit(
        state.copyWith(
          searched: '',
          stories: const [],
          bodyResults: const [],
          loading: false,
          failed: false,
        ),
      );
      return;
    }
    emit(state.copyWith(loading: true, failed: false));
    _sub = switch (scope) {
      SearchScope.body =>
        _repo
            .watchEntries(EntryFilter.body(term))
            .listen(
              (r) => _found(term, state.copyWith(bodyResults: r)),
              onError: _onError,
            ),
      SearchScope.story =>
        _repo
            .watchStoryMatches(term, dailyTitle: _dailyTitle)
            .listen(
              (r) => _found(term, state.copyWith(stories: r)),
              onError: _onError,
            ),
      SearchScope.tag =>
        _repo
            .watchTagCounts(query: term)
            .listen(
              (r) => _found(term, state.copyWith(suggestions: r)),
              onError: _onError,
            ),
      SearchScope.place =>
        _repo
            .watchPlaceCounts(query: term)
            .listen(
              (r) => _found(term, state.copyWith(suggestions: r)),
              onError: _onError,
            ),
    };
  }

  void _found(String term, DiarySearchState next) =>
      emit(next.copyWith(searched: term, loading: false));

  void _onError(Object _) => emit(state.copyWith(loading: false, failed: true));

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
