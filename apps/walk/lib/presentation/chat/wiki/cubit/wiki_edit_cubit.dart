import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import 'wiki_edit_state.dart';

/// 메모 편집 화면. 쓰던 글을 [WikiEditState.seed] 에 남겨 잠겼다 풀려도 그대로 그린다.
class WikiEditCubit extends Cubit<WikiEditState> {
  WikiEditCubit(this._wiki, {required WikiEditSeed seed})
    : super(WikiEditState(seed: seed));

  final WikiRepository _wiki;

  /// 칸이 바뀌었다. 쓰던 글을 남기고 오류 표시를 지운다.
  void changed({String? title, String? summary, String? body}) {
    final seed = state.seed;
    emit(
      state.copyWith(
        seed: seed.copyWith(
          title: title ?? seed.title,
          summary: summary ?? seed.summary,
          body: body ?? seed.body,
        ),
        error: null,
      ),
    );
  }

  /// 성공하면 메모 id. 제목 · 요약이 비면 error 만 두고 null. 저장 중이면 무시(null).
  Future<int?> save({
    required String title,
    required String summary,
    required String body,
  }) async {
    if (state.saving) return null;
    final seed = state.seed.copyWith(
      title: title,
      summary: summary,
      body: body,
    );
    final t = title.trim();
    final s = summary.trim();
    if (t.isEmpty || s.isEmpty) {
      emit(
        state.copyWith(
          seed: seed,
          error: t.isEmpty
              ? WikiEditError.emptyTitle
              : WikiEditError.emptySummary,
        ),
      );
      return null;
    }
    emit(state.copyWith(seed: seed, saving: true, error: null));
    final draft = WikiNoteDraft(
      title: t,
      summary: s,
      body: body.trim(),
      sourceConversationId: seed.sourceConversationId,
    );
    try {
      final id = seed.id;
      if (id == null) {
        final created = await _wiki.create(draft);
        if (!isClosed) {
          emit(state.copyWith(seed: seed.copyWith(id: created), saving: false));
        }
        return created;
      }
      await _wiki.update(id, draft);
      if (!isClosed) emit(state.copyWith(saving: false));
      return id;
    } on Object {
      if (!isClosed) {
        emit(state.copyWith(saving: false, error: WikiEditError.saveFailed));
      }
      return null;
    }
  }
}
