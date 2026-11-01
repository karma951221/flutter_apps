import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/chat_history_repository.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import '../../../../domain/chat/usecase/chat_session.dart';
import '../../../../domain/chat/usecase/wiki_distiller.dart';
import '../../../../domain/diary/entity/diary_entry.dart';
import '../../../../domain/diary/repository/diary_repository.dart';
import 'wiki_distill_state.dart';

/// [위키로 정리] 후보 시트(D6). 생성하자마자 정리 요청을 낸다. 저장은 [save] · [markSaved] 로
/// 후보마다 사용자가 고른 것만 — 닫으면 남은 후보는 버린다(보류 목록 없음).
///
/// 요청 중에 닫으면 [WikiDistiller.cancel] 로 HTTP 를 끊는다.
class WikiDistillCubit extends Cubit<WikiDistillState> {
  WikiDistillCubit(
    this._distiller,
    this._wiki,
    this._history,
    this._diary, {
    required String conversationId,
    required ChatTarget? target,
  }) : _conversationId = conversationId,
       super(const WikiDistillState.loading()) {
    unawaited(_start(target));
  }

  final WikiDistiller _distiller;
  final WikiRepository _wiki;
  final ChatHistoryRepository _history;
  final DiaryRepository _diary;
  final String _conversationId;

  /// 저장 중인 후보 — 두 번 눌러도 한 번만 쓴다.
  final _saving = <int>{};

  Future<void> _start(ChatTarget? target) async {
    final WikiDistillResult result;
    try {
      result = await _distiller.distill(
        conversationId: _conversationId,
        target: target,
      );
    } on Object {
      if (!isClosed) emit(const WikiDistillState.failed(ChatFailure.unknown));
      return;
    }
    if (isClosed) return;
    switch (result) {
      case WikiDistillCancelled():
        return;
      case WikiDistillFailed(:final failure):
        emit(WikiDistillState.failed(failure));
      case WikiDistillUnparsable():
        emit(const WikiDistillState.unparsable());
      case WikiDistillCandidates(:final candidates):
        await _ready(candidates);
    }
  }

  /// 후보 + 링크 칩에 쓸 메모 · 일기를 읽어 ready.
  ///
  /// 그새 지워진 메모를 고치는 후보는 새 메모 후보로 바꾼다(W8). 칩용 일기는 대화의 근거 일기 +
  /// 후보 본문 · 지금 본문이 가리키는 일기 — 근거가 아닌 살아 있는 일기도 '지워진 일기'로 보이지 않게.
  Future<void> _ready(List<WikiCandidate> raw) async {
    try {
      final notes = {for (final n in await _wiki.all()) n.id: n};
      final candidates = [
        for (final c in raw)
          switch (c) {
            WikiUpdateCandidate(
              :final id,
              :final title,
              :final summary,
              :final body,
            )
                when !notes.containsKey(id) =>
              WikiCandidate.create(title: title, summary: summary, body: body),
            _ => c,
          },
      ];
      final cited = <String>{
        for (final turn in await _history.turns(_conversationId))
          ...turn.citedEntryIds,
      }.toList();
      final linked = <String>{
        ...cited,
        for (final c in candidates) ..._diaryIdsIn(c.body),
        for (final c in candidates)
          if (c case WikiUpdateCandidate(:final id))
            ..._diaryIdsIn(notes[id]!.body),
      };
      final entries = <String, DiaryEntry>{};
      for (final id in linked) {
        if (await _diary.entry(id) case Ok(
          :final value,
        ) when !value.isTrashed) {
          entries[id] = value;
        }
      }
      if (isClosed) return;
      emit(
        WikiDistillState.ready(
          [
            for (final c in candidates)
              CandidateItem(
                candidate: c,
                current: switch (c) {
                  WikiUpdateCandidate(:final id) => notes[id],
                  WikiCreateCandidate() => null,
                },
              ),
          ],
          notes: notes,
          entries: entries,
          citedEntryIds: cited,
        ),
      );
    } on Object {
      if (!isClosed) emit(const WikiDistillState.failed(ChatFailure.unknown));
    }
  }

  static Iterable<String> _diaryIdsIn(String body) => [
    for (final l in wikiLinksIn(body))
      if (l case WikiDiaryLink(:final entryId)) entryId,
  ];

  /// 대화 id — [고쳐서 저장] 편집 값의 출처.
  String get conversationId => _conversationId;

  /// [저장] — create 는 출처 = 이 대화, update 는 출처 그대로(draft 의 출처 null).
  /// 저장소가 던지면 그대로 던진다(후보는 pending 그대로) — 화면이 알린다.
  Future<void> save(int index) async {
    final item = _pending(index);
    if (item == null || !_saving.add(index)) return;
    try {
      switch (item.candidate) {
        case WikiCreateCandidate(:final title, :final summary, :final body):
          await _wiki.create(
            WikiNoteDraft(
              title: title,
              summary: summary,
              body: body,
              sourceConversationId: _conversationId,
            ),
          );
        case WikiUpdateCandidate(
          :final id,
          :final title,
          :final summary,
          :final body,
        ):
          await _wiki.update(
            id,
            WikiNoteDraft(title: title, summary: summary, body: body),
          );
      }
    } finally {
      _saving.remove(index);
    }
    _mark(index, CandidateStatus.saved);
  }

  /// [고쳐서 저장] 이 저장을 끝냈을 때.
  void markSaved(int index) => _mark(index, CandidateStatus.saved);

  void discard(int index) => _mark(index, CandidateStatus.discarded);

  /// 후보가 모두 저장 · 버림 됐다. 빈 목록 · ready 전이면 false.
  bool get allHandled => switch (state) {
    WikiDistillReady(:final items) =>
      items.isNotEmpty &&
          items.every((i) => i.status != CandidateStatus.pending),
    _ => false,
  };

  int get savedCount => switch (state) {
    WikiDistillReady(:final items) =>
      items.where((i) => i.status == CandidateStatus.saved).length,
    _ => 0,
  };

  CandidateItem? _pending(int index) => switch (state) {
    WikiDistillReady(:final items)
        when index >= 0 &&
            index < items.length &&
            items[index].status == CandidateStatus.pending =>
      items[index],
    _ => null,
  };

  /// 저장 중인 카드는 [discard] · [markSaved] 를 받지 않는다 — 저장이 끝나면 '저장함'.
  void _mark(int index, CandidateStatus status) {
    if (isClosed || _saving.contains(index)) return;
    final s = state;
    if (s is! WikiDistillReady || _pending(index) == null) return;
    final items = [...s.items];
    items[index] = items[index].copyWith(status: status);
    emit(s.copyWith(items: List.unmodifiable(items)));
  }

  @override
  Future<void> close() {
    if (state is WikiDistillLoading) _distiller.cancel();
    return super.close();
  }
}
