import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/diary/draft/draft_context.dart';
import '../../../domain/diary/draft/draft_writer.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import 'draft_state.dart';

/// 작성 화면의 자동 초안(스펙 2026-11-15 §4). 메모는 글 칸의 글이고, 초안은 글 칸에 흘려 넣는다.
///
/// 글 칸을 바꿀 때마다 [onBody] 를 부른다 — 작성 화면이 잠겨 사라져도 쓰던 글([EntryEditorCubit])이
/// 그 글로 남는다. 문체는 늘 일기 설정의 값, 사진 보여 주기는 설정에 기억한다.
class DraftCubit extends Cubit<DraftState> {
  DraftCubit(
    this._writer,
    this._prefs,
    this._settings, {
    required void Function(String body) onBody,
  }) : _onBody = onBody,
       super(DraftState(includePhotos: _prefs.draftIncludePhotos));

  final DraftWriter _writer;
  final DiaryPreferences _prefs;
  final ChatSettings _settings;
  final void Function(String body) _onBody;

  StreamSubscription<DraftEvent>? _run;

  /// 키 · 동의 상태(✨ 를 누를 때마다 다시 읽는다).
  Future<DraftAvailability> availability() => _writer.availability();

  /// 연결 벤더(사진 전송 확인 문구). 없으면 null.
  ChatVendor? get vendor => _settings.connectedVendor;

  /// 초안 모델이 사진을 볼 수 있는가.
  bool get canSeePhotos => _writer.canSeePhotos;

  /// [vendor] 로의 초안 전송 동의를 기록한다. 초안 문구엔 위치 기록이 없어 물어보기 동의는 아니다.
  Future<void> consent(ChatVendor vendor) =>
      _settings.setDraftConsented(vendor);

  Future<void> setIncludePhotos(bool on) async {
    emit(state.copyWith(includePhotos: on));
    await _prefs.setDraftIncludePhotos(on);
  }

  /// ✨ — 글 칸의 [body] 로 초안을 쓴다. 쓰는 중이면 무시한다.
  /// - 처음(또는 되돌린 뒤): [body] 를 메모로.
  /// - 글 칸이 마지막 초안 그대로: 마지막 요청의 메모로 다시(R-A3).
  /// - 초안을 고쳤으면: 고친 글을 다듬는다.
  void generate({
    required String body,
    required DraftContext Function(String memo) contextFor,
    required List<EntryMedia> photos,
  }) {
    if (state.writing) return;
    final last = state.lastDraft;
    final String memo;
    final bool polish;
    if (last != null && body == last && state.memo != null) {
      memo = state.memo!;
      polish = state.polish;
    } else {
      memo = body;
      polish = last != null && body.trim().isNotEmpty;
    }
    final hasPhotos = photos.any((m) => m.kind == MediaKind.photo);
    _setText(
      state.copyWith(
        run: const DraftRun.writing(),
        memo: memo,
        polish: polish,
        text: '',
      ),
    );
    _run = _writer
        .write(
          contextFor(memo),
          style: _prefs.draftStyle,
          photos: photos,
          includePhotos: state.includePhotos && hasPhotos,
          polish: polish,
        )
        .listen(_onEvent);
  }

  void _onEvent(DraftEvent event) {
    switch (event) {
      case DraftDelta(:final text):
        _setText(state.copyWith(text: state.text + text));
      case DraftDone(:final text):
        _run = null;
        _setText(
          state.copyWith(
            run: const DraftRun.done(),
            text: text,
            lastDraft: text,
          ),
        );
      case DraftFailed(:final failure):
        _run = null;
        _setText(
          state.copyWith(run: DraftRun.failed(failure), text: state.memo ?? ''),
        );
      case DraftNeedsConsent():
        _run = null;
        _setText(
          state.copyWith(run: const DraftRun.idle(), text: state.memo ?? ''),
        );
    }
  }

  /// [멈추기] · 잠김(R-A9). 그때까지의 글이 남고(없으면 원래 메모), 그 글이 마지막 초안이 된다.
  Future<void> stop() async {
    final run = _run;
    if (run == null || !state.writing) return;
    _run = null;
    // 끊기를 기다리지 않고 글 칸부터 정한다 — 늦게 온 조각은 구독이 끊겨 버려진다.
    final cancelling = run.cancel();
    final partial = state.text;
    _setText(
      partial.trim().isEmpty
          ? state.copyWith(run: const DraftRun.idle(), text: state.memo ?? '')
          : state.copyWith(run: const DraftRun.idle(), lastDraft: partial),
    );
    await cancelling;
  }

  /// [되돌리기] — 원래 메모로. 다음 ✨ 는 처음 쓰기다.
  void undo() {
    if (state.writing) return;
    _setText(
      state.copyWith(
        run: const DraftRun.idle(),
        text: state.memo ?? state.text,
        lastDraft: null,
      ),
    );
  }

  void _setText(DraftState next) {
    final changed = next.text != state.text || next.run != state.run;
    emit(next);
    if (changed) _onBody(next.text);
  }

  @override
  Future<void> close() async {
    await _run?.cancel();
    _run = null;
    return super.close();
  }
}
