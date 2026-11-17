import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/chat_history_repository.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import '../../../../domain/diary/entity/diary_entry.dart';
import '../../../../domain/diary/repository/diary_repository.dart';
import 'wiki_note_state.dart';

/// 메모 보기 화면. 메모 하나를 구독하고, 받을 때마다 본문의 링크(메모 · 일기) ·
/// 역링크 · 출처 대화가 남았는지를 다시 읽는다. 메모가 사라지면 [WikiNoteState.deleted].
class WikiNoteCubit extends Cubit<WikiNoteState> {
  WikiNoteCubit(this._wiki, this._diary, this._history, {required int id})
    : _id = id,
      super(const WikiNoteState()) {
    _subscription = _wiki
        .watchNote(id)
        .listen(
          _load,
          onError: (Object _) {
            if (!isClosed) emit(state.copyWith(loading: false, failed: true));
          },
        );
  }

  final WikiRepository _wiki;
  final DiaryRepository _diary;
  final ChatHistoryRepository _history;
  final int _id;
  late final StreamSubscription<WikiNote?> _subscription;

  /// 늦게 끝난 앞선 읽기가 새 결과를 덮지 않게.
  int _generation = 0;

  Future<void> _load(WikiNote? note) async {
    final generation = ++_generation;
    if (note == null) {
      emit(state.copyWith(loading: false, note: null, deleted: true));
      return;
    }
    try {
      final links = wikiLinksIn(note.body);
      final noteIds = [
        for (final l in links)
          if (l case WikiNoteLink(:final id)) id,
      ];
      final entryIds = [
        for (final l in links)
          if (l case WikiDiaryLink(:final entryId)) entryId,
      ];
      final linked = await _wiki.byIds(noteIds);
      final entries = <String, DiaryEntry>{};
      for (final id in entryIds) {
        if (await _diary.entry(id) case Ok(:final value) when !value.isTrashed) {
          entries[id] = value;
        }
      }
      final backlinks = await _wiki.backlinks(_id);
      final source = note.sourceConversationId;
      final sourceExists =
          source != null && await _history.watchExists(source).first;
      if (isClosed || generation != _generation) return;
      emit(
        WikiNoteState(
          loading: false,
          note: note,
          linkedNotes: {for (final n in linked) n.id: n},
          linkedEntries: entries,
          backlinks: backlinks,
          sourceExists: sourceExists,
        ),
      );
    } on Object {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(loading: false, note: note, failed: true));
    }
  }

  /// 링크된 화면에서 돌아온 뒤 — 링크 · 역링크를 다시 읽는다.
  Future<void> reload() async {
    final note = state.note;
    if (note != null && !state.deleted) await _load(note);
  }

  /// 저장소가 던지면 그대로 던진다 — 화면이 실패를 알린다. 성공하면 구독이 [WikiNoteState.deleted] 를 낸다.
  Future<void> delete() => _wiki.delete(_id);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
