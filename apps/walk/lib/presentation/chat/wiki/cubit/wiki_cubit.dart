import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/chat/chat_history_settings.dart';
import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import '../../../../domain/chat/wiki/wiki_index.dart';
import 'wiki_state.dart';

/// 위키 화면. 만들 때 저장소의 목록을 구독하고, 받을 때마다 지금 색인 크기로
/// [buildWikiIndex] 를 돌려 색인에 실린 메모를 표시한다(W1). 목록을 읽지 못하면 [WikiState.failed].
class WikiCubit extends Cubit<WikiState> {
  WikiCubit(this._wiki, this._settings)
    : super(WikiState(size: _settings.wikiIndexSize)) {
    _subscription = _wiki.notes().listen(
      (notes) => emit(_withIndex(notes, state.size, failed: false)),
      onError: (Object _) {
        if (!isClosed) emit(state.copyWith(loading: false, failed: true));
      },
    );
  }

  final WikiRepository _wiki;
  final ChatHistorySettings _settings;
  late final StreamSubscription<List<WikiNote>> _subscription;

  WikiState _withIndex(
    List<WikiNote> notes,
    WikiIndexSize size, {
    required bool failed,
  }) => state.copyWith(
    loading: false,
    failed: failed,
    notes: notes,
    size: size,
    indexedIds: buildWikiIndex(notes, size).includedIds.toSet(),
  );

  /// 지운 수. 저장소가 던지면 그대로 던진다 — 화면이 실패를 알린다.
  Future<int> deleteAll() => _wiki.deleteAll();

  /// 색인 크기 시트에서 돌아온 뒤 — 설정을 다시 읽어 색인 표시를 고친다.
  void refreshSize() {
    final size = _settings.wikiIndexSize;
    if (size == state.size) return;
    if (state.loading) return emit(state.copyWith(size: size));
    emit(_withIndex(state.notes, size, failed: state.failed));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
