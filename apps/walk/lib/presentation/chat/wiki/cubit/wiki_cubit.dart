import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/chat/chat_history_settings.dart';
import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import '../../../../domain/chat/wiki/wiki_index.dart';
import 'wiki_state.dart';

/// 위키 화면. 구독을 셋 둔다.
///
/// - 목록: [WikiRepository.watchNotes] 를 (지금 쪽 수 × [pageSize]) + 1 개로 구독해, 하나 더
///   오면 [WikiState.hasMore]. [loadMore] 는 한도를 한 쪽 늘려 다시 구독한다.
/// - 색인: 최근 [wikiIndexWindow] 개 + 전체 수로 [buildWikiIndex] 를 돌려 색인에 실린 메모를
///   표시한다(W1). 검색과 무관하다.
///
/// 검색어는 [debounce] 뒤에 첫 쪽부터 다시 찾는다. 어느 구독이든 오류면 [WikiState.failed].
class WikiCubit extends Cubit<WikiState> {
  WikiCubit(
    this._wiki,
    this._settings, {
    this.pageSize = 30,
    Duration debounce = const Duration(milliseconds: 300),
  }) : _debounce = debounce,
       _limit = pageSize,
       super(WikiState(size: _settings.wikiIndexSize)) {
    _countSub = _wiki.watchCount().listen((n) {
      _total = n;
      _emitIndex();
    }, onError: _onError);
    _subscribeIndex();
    _subscribeList();
  }

  final WikiRepository _wiki;
  final ChatHistorySettings _settings;

  /// 한 번에 더 읽는 메모 수.
  final int pageSize;
  final Duration _debounce;

  int _limit;
  Timer? _timer;
  StreamSubscription<List<WikiNote>>? _listSub;
  StreamSubscription<List<WikiNote>>? _indexSub;
  late final StreamSubscription<int> _countSub;

  /// 색인 창 메모 · 전체 수 — 둘 다 받아야 색인을 계산한다.
  List<WikiNote>? _window;
  int? _total;

  void _subscribeList() {
    unawaited(_listSub?.cancel());
    final term = state.searched;
    final limit = _limit;
    _listSub = _wiki.watchNotes(query: term, limit: limit + 1).listen((rows) {
      emit(
        state.copyWith(
          loading: false,
          loadingMore: false,
          notes: rows.length > limit ? rows.sublist(0, limit) : rows,
          hasMore: rows.length > limit,
        ),
      );
    }, onError: _onError);
  }

  void _subscribeIndex() {
    unawaited(_indexSub?.cancel());
    _window = null;
    _indexSub = _wiki.watchNotes(limit: wikiIndexWindow(state.size)).listen((
      rows,
    ) {
      _window = rows;
      _emitIndex();
    }, onError: _onError);
  }

  void _emitIndex() {
    final window = _window;
    final total = _total;
    if (window == null || total == null) return;
    final index = buildWikiIndex(window, state.size, total: total);
    emit(
      state.copyWith(
        total: total,
        indexedIds: index.includedIds.toSet(),
        indexChars: index.chars,
      ),
    );
  }

  void _onError(Object _) {
    if (!isClosed) {
      emit(state.copyWith(loading: false, loadingMore: false, failed: true));
    }
  }

  /// 목록 끝 가까이에서 부른다. 더 없거나 이미 읽는 중이면 아무것도 하지 않는다.
  void loadMore() {
    if (!state.hasMore || state.loadingMore) return;
    _limit += pageSize;
    emit(state.copyWith(loadingMore: true));
    _subscribeList();
  }

  /// 같은 입력이면 아무것도 하지 않는다. [debounce] 뒤에 첫 쪽부터 찾는다.
  void setQuery(String q) {
    if (q == state.query) return;
    emit(state.copyWith(query: q));
    _timer?.cancel();
    _timer = Timer(_debounce, _search);
  }

  void _search() {
    final term = state.query.trim();
    if (term == state.searched) return;
    _limit = pageSize;
    emit(state.copyWith(searched: term, loadingMore: false));
    _subscribeList();
  }

  /// 지운 수. 저장소가 던지면 그대로 던진다 — 화면이 실패를 알린다.
  Future<int> deleteAll() => _wiki.deleteAll();

  /// 색인 크기 시트에서 돌아온 뒤 — 설정을 다시 읽어 색인 표시를 고친다.
  void refreshSize() {
    final size = _settings.wikiIndexSize;
    if (size == state.size) return;
    emit(state.copyWith(size: size));
    _subscribeIndex();
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _listSub?.cancel();
    await _indexSub?.cancel();
    await _countSub.cancel();
    return super.close();
  }
}
