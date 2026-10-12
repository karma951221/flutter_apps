import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/diary_failure.dart';
import '../../../domain/diary/entity/entry_draft.dart';
import '../../../domain/diary/entity/entry_location.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/media_limits.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/entity/tag_name.dart';
import '../../../domain/diary/location/place_source.dart';
import '../../../domain/diary/media/media_store.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_order.dart';
import '../../../domain/diary/usecase/story_suggestion.dart';
import '../media_picker.dart';
import 'entry_editor_state.dart';

/// 기록 작성 · 수정(스펙 §6.2). 저장 · 취소의 파일 정리는 [DiaryUseCase] 가 한다.
class EntryEditorCubit extends Cubit<EntryEditorState> {
  EntryEditorCubit(
    this._useCase,
    this._repo,
    this._media,
    this._places,
    this._clock,
  ) : super(_blank(_clock.now()));

  final DiaryUseCase _useCase;
  final DiaryRepository _repo;
  final MediaStore _media;
  final PlaceSource _places;
  final Clock _clock;

  StreamSubscription<List<Story>>? _stories;

  /// 시작했을 때의 입력. 이것과 다르면 닫을 때 버릴지 묻는다.
  EntryDraft? _baseline;

  /// [cancel] 뒤에 끝난 가져오기는 바로 버린다.
  bool _cancelled = false;

  static EntryEditorState _blank(DateTime now) => EntryEditorState(
    draft: EntryDraft(
      storyId: Story.dailyId,
      body: '',
      occurredAt: now,
      media: const [],
      tags: const [],
    ),
    createdAt: now,
  );

  /// 시작한 뒤 입력을 바꿨는지. 자동으로 붙은 지금 위치는 바꾼 것으로 치지 않는다.
  bool get hasChanges => _baseline != null && state.draft != _baseline;

  /// 기본 스토리(`StorySuggestion.defaultFor`), 시각은 지금, 그다음 지금 위치를 찾는다.
  /// 위치를 찾는 동안 시각을 바꾸거나 위치를 빼면 늦게 온 위치를 버린다.
  Future<void> startNew() async {
    final now = _clock.now();
    final stories = await _watchStories();
    if (isClosed) return;
    final draft = EntryDraft(
      storyId: StorySuggestion.defaultFor(stories),
      body: '',
      occurredAt: now,
      media: const [],
      tags: const [],
    );
    _baseline = draft;
    emit(state.copyWith(draft: draft, createdAt: now, locating: true));

    EntryLocation? location;
    try {
      location = await _places.current();
    } catch (_) {
      // 위치 실패는 오류가 아니다 — 위치 없이 쓴다.
    }
    if (isClosed) return;
    if (state.manualPlace) {
      emit(state.copyWith(locating: false));
      return;
    }
    _baseline = _baseline?.copyWith(location: location);
    emit(
      state.copyWith(
        locating: false,
        manualPlace: location == null,
        draft: state.draft.copyWith(location: location),
      ),
    );
  }

  /// 기록을 읽어 채운다. 좌표가 없는 기록은 장소 이름을 직접 고친다.
  Future<void> startEdit(String entryId) async {
    unawaited(_watchStories());
    switch (await _repo.entry(entryId)) {
      case Err(:final failure):
        if (!isClosed) _reportFailure(failure);
      case Ok(value: final entry):
        if (isClosed) return;
        if (entry.isTrashed) {
          _report(DiaryFailure.notFound);
          return;
        }
        final draft = EntryDraft(
          storyId: entry.storyId,
          body: entry.body,
          occurredAt: entry.occurredAt,
          location: entry.location,
          media: entry.media,
          tags: entry.tags,
        );
        _baseline = draft;
        emit(
          state.copyWith(
            editingId: entry.id,
            draft: draft,
            createdAt: entry.createdAt,
            manualPlace: !(entry.location?.hasCoordinates ?? false),
          ),
        );
    }
  }

  /// 미래면 무시한다. 새 기록을 과거로 옮기면 지금 위치(좌표)를 빼고 장소를 직접 입력한다.
  /// 그 시각이 든 열린 스토리를 제안한다(없으면 '일상'). 닫힌 스토리의 기록은 옮기지 않는다.
  void setTime(DateTime at) {
    if (at.isAfter(_clock.now())) return;
    var draft = state.draft.copyWith(occurredAt: at);
    var manualPlace = state.manualPlace;
    if (!state.isEditing && at != state.createdAt) {
      manualPlace = true;
      if (draft.location?.hasCoordinates ?? false) {
        draft = draft.copyWith(location: null);
      }
    }
    final current = state.stories
        .where((s) => s.id == draft.storyId)
        .firstOrNull;
    if (current == null || current.isOpen) {
      draft = draft.copyWith(
        storyId: StorySuggestion.forTime(state.stories, at),
      );
    }
    emit(state.copyWith(draft: draft, manualPlace: manualPlace));
  }

  /// 기록 시각을 [EntryEditorState.createdAt] 으로 되돌린다.
  void revertTime() => emit(
    state.copyWith(draft: state.draft.copyWith(occurredAt: state.createdAt)),
  );

  void setStory(String storyId) =>
      emit(state.copyWith(draft: state.draft.copyWith(storyId: storyId)));

  void setBody(String body) =>
      emit(state.copyWith(draft: state.draft.copyWith(body: body)));

  /// `TagName.normalize` 로 다듬는다. 빈 입력 · 30자 초과 · 이미 있는 칩은 무시한다.
  void addTag(String raw) {
    final name = TagName.normalize(raw);
    if (name == null || state.draft.tags.contains(name)) return;
    emit(
      state.copyWith(
        draft: state.draft.copyWith(tags: [...state.draft.tags, name]),
      ),
    );
  }

  void removeTag(String name) => emit(
    state.copyWith(
      draft: state.draft.copyWith(
        tags: [
          for (final t in state.draft.tags)
            if (t != name) t,
        ],
      ),
    ),
  );

  /// 직접 입력한 장소 이름(좌표 없음). 비면 위치 없음.
  void setPlaceName(String? name) {
    final trimmed = name?.trim() ?? '';
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          location: trimmed.isEmpty ? null : EntryLocation(placeName: trimmed),
        ),
      ),
    );
  }

  /// 위치를 빼고 장소 이름 직접 입력으로 바꾼다.
  void clearLocation() => emit(
    state.copyWith(
      manualPlace: true,
      draft: state.draft.copyWith(location: null),
    ),
  );

  /// 고른 순서대로 **하나씩** 임시 사본을 만든다(영상 압축은 동시에 하나만 된다).
  /// 10개를 넘는 것은 가져오지 않고 tooManyMedia, 30초 넘는 영상 · 처리 실패는 건너뛰고
  /// 마지막 오류를 알린다. 가져오는 중에 다시 부르면 무시한다.
  Future<void> addMedia(List<PickedMedia> picked) async {
    if (picked.isEmpty || state.importing || state.saving || state.saved) {
      return;
    }
    emit(state.copyWith(importing: true));
    DiaryFailure? error;
    var failed = false;
    for (final p in picked) {
      if (!MediaLimits.canAdd(state.draft.media.length, 1)) {
        error = DiaryFailure.tooManyMedia;
        break;
      }
      final result = switch (p.kind) {
        MediaKind.photo => await _media.importPhoto(p.path),
        MediaKind.video => await _media.importVideo(p.path),
      };
      if (isClosed || _cancelled) {
        if (result case Ok(:final value)) await _useCase.cancelDraft([value]);
        return;
      }
      switch (result) {
        case Ok(:final value):
          emit(
            state.copyWith(
              draft: state.draft.copyWith(media: [...state.draft.media, value]),
              newMedia: [...state.newMedia, value],
            ),
          );
        case Err(:final failure):
          final diary = _diaryFailureOf(failure);
          if (diary == null) {
            failed = true;
          } else {
            error = diary;
          }
      }
    }
    emit(state.copyWith(importing: false));
    if (error != null) {
      _report(error);
    } else if (failed) {
      _reportFailed();
    }
  }

  /// 새로 가져온 것이면 임시 사본을 바로 지운다. 원래 있던 것은 저장이 성공한 뒤에만
  /// [DiaryUseCase.save] 가 지운다.
  void removeMedia(String mediaId) {
    final removed = state.draft.media.where((m) => m.id == mediaId).firstOrNull;
    if (removed == null) return;
    final isNew = state.newMedia.any((m) => m.id == mediaId);
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          media: [
            for (final m in state.draft.media)
              if (m.id != mediaId) m,
          ],
        ),
        newMedia: [
          for (final m in state.newMedia)
            if (m.id != mediaId) m,
        ],
      ),
    );
    if (isNew) unawaited(_useCase.cancelDraft([removed]));
  }

  /// [from] 자리의 미디어를 빼서 [to] 자리(뺀 뒤 목록 기준)에 넣는다.
  void reorderMedia(int from, int to) {
    final media = [...state.draft.media];
    if (from < 0 || from >= media.length || to < 0 || to >= media.length) {
      return;
    }
    media.insert(to, media.removeAt(from));
    emit(state.copyWith(draft: state.draft.copyWith(media: media)));
  }

  /// 저장 중 · 가져오는 중 · 저장한 뒤에는 무시한다.
  Future<void> save() async {
    if (state.saving || state.importing || state.saved) return;
    emit(state.copyWith(saving: true));
    final result = await _useCase.save(state.draft, editingId: state.editingId);
    if (isClosed) return;
    switch (result) {
      case Ok():
        emit(state.copyWith(saving: false, saved: true, newMedia: const []));
      case Err(:final failure):
        emit(state.copyWith(saving: false));
        _reportFailure(failure);
    }
  }

  /// 저장하지 않고 닫는다: 새로 가져온 임시 사본을 지운다.
  Future<void> cancel() async {
    if (state.saved) return;
    _cancelled = true;
    final discard = state.newMedia;
    emit(state.copyWith(newMedia: const []));
    await _useCase.cancelDraft(discard);
  }

  /// 스토리 목록을 구독하고 첫 목록을 돌려준다. 읽지 못하면 빈 목록('일상'만).
  Future<List<Story>> _watchStories() {
    final first = Completer<List<Story>>();
    unawaited(_stories?.cancel());
    _stories = _repo.watchStories().listen(
      (stories) {
        if (!first.isCompleted) first.complete(stories);
        emit(
          state.copyWith(
            stories: stories,
            openStories: StoryOrder.split(stories).open,
          ),
        );
      },
      onError: (Object _) {
        if (!first.isCompleted) first.complete(const []);
      },
    );
    return first.future;
  }

  static DiaryFailure? _diaryFailureOf(Failure failure) => switch (failure) {
    ValidationFailure(:final field) =>
      DiaryFailure.values.where((f) => f.name == field).firstOrNull,
    NotFoundFailure() => DiaryFailure.notFound,
    _ => null,
  };

  void _reportFailure(Failure failure) {
    final diary = _diaryFailureOf(failure);
    if (diary == null) {
      _reportFailed();
    } else {
      _report(diary);
    }
  }

  /// 같은 오류가 이어져도 화면이 다시 알리도록 비운 상태를 먼저 내보낸다.
  void _report(DiaryFailure error) {
    emit(state.copyWith(error: null, failed: false));
    emit(state.copyWith(error: error));
  }

  void _reportFailed() {
    emit(state.copyWith(error: null, failed: false));
    emit(state.copyWith(failed: true));
  }

  @override
  Future<void> close() async {
    await _stories?.cancel();
    return super.close();
  }
}
