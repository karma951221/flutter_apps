import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/diary/diary_failure.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_order.dart';
import 'story_manage_state.dart';

/// 스토리 관리(스펙 §6.3): 만들기 · 닫기 · 다시 열기 · 이름 · 표지 · 삭제 · '일상' 기록 옮기기.
///
/// 목록은 저장소 스트림으로 들어온다. 동작이 실패하면 [StoryManageState.error] ·
/// [StoryManageState.actionFailed] 에 남기고, 다음 동작을 시작할 때 비운다 — 화면은
/// 동작을 기다린 뒤 이 둘로 성공을 판단한다. 확인 다이얼로그는 화면이 띄운다.
class StoryManageCubit extends Cubit<StoryManageState> {
  StoryManageCubit(this._repo, this._useCase, this._clock)
    : super(const StoryManageState());

  final DiaryRepository _repo;
  final DiaryUseCase _useCase;
  final Clock _clock;

  StreamSubscription<List<Story>>? _stories;

  void start() {
    unawaited(_stories?.cancel());
    _stories = _repo.watchStories().listen(
      (stories) {
        final split = StoryOrder.split(stories);
        emit(
          state.copyWith(
            open: split.open,
            archived: split.archived,
            loading: false,
            failed: false,
          ),
        );
      },
      onError: (Object _) => emit(state.copyWith(loading: false, failed: true)),
    );
  }

  /// 제목은 앞뒤 공백을 뗀다. [endedAt] 이 있으면 닫힌 스토리(보관함)로 만든다.
  Future<void> create({
    required String title,
    required DateTime startedAt,
    DateTime? endedAt,
  }) async {
    _begin();
    emit(state.copyWith(created: null));
    final result = await _repo.createStory(
      title: title.trim(),
      startedAt: startedAt,
      endedAt: endedAt,
    );
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(created: value));
      case Err(:final failure):
        _fail(failure);
    }
  }

  /// [from] ~ [to] 의 '일상' 기록(휴지통 제외), 최신순. 지난 기간 스토리를 만들 때 옮길 후보.
  Future<List<DiaryEntry>> dailyEntriesIn(DateTime from, DateTime to) =>
      _repo.entriesBetween(from, to, storyId: Story.dailyId);

  /// 기록들을 [storyId] 로 옮긴다. 저장소는 닫힌 스토리로의 이동을 거절하므로(`storyClosed` —
  /// 닫힌 스토리에 새로 쓰지 않는 규칙), 지난 기간으로 만든 닫힌 스토리면 잠시 열고
  /// 옮긴 뒤 같은 종료일로 다시 닫는다. 옮기다 실패해도 다시 닫는다.
  Future<void> moveIn(List<String> entryIds, String storyId) async {
    _begin();
    if (entryIds.isEmpty) return;
    final target =
        _find(storyId) ?? (state.created?.id == storyId ? state.created : null);
    if (target == null || target.isOpen) {
      _settle(await _repo.moveEntries(entryIds, storyId));
      return;
    }
    final reopened = target.copyWith(status: StoryStatus.open, endedAt: null);
    if (await _repo.updateStory(reopened) case Err(:final failure)) {
      _fail(failure);
      return;
    }
    final moved = await _repo.moveEntries(entryIds, storyId);
    final reclosed = await _repo.updateStory(target);
    _settle(moved);
    _settle(reclosed);
  }

  /// [at] 이 없으면 지금 닫는다. 기본 스토리 · 시작 전 날은 거절한다.
  /// (브리프의 `close(id)` — cubit 자신의 [close] 와 이름이 겹쳐 `closeStory` 다.)
  Future<void> closeStory(String id, {DateTime? at}) =>
      _change(id, (s) => s.close(at ?? _clock.now()));

  Future<void> reopen(String id) => _change(id, (s) => s.reopen());

  /// 앞뒤 공백을 뗀다. 기본 스토리는 비우면 기본 이름(l10n)으로 돌아가고,
  /// 다른 스토리는 빈 이름을 받지 않는다(아무것도 하지 않는다).
  Future<void> rename(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty && id != Story.dailyId) {
      _begin();
      return;
    }
    await _change(id, (s) => Ok(s.copyWith(title: trimmed)));
  }

  /// [mediaId] 가 null 이면 자동 표지(가장 최근 사진)로 되돌린다.
  Future<void> setCover(String id, String? mediaId) =>
      _change(id, (s) => Ok(s.copyWith(coverMediaId: mediaId)));

  /// 기록은 휴지통으로 가고 스토리는 지워진다(스펙 §5.1). 기본 스토리는 거절한다.
  Future<void> delete(String id) async {
    _begin();
    _settle(await _useCase.deleteStory(id));
  }

  /// 표지로 고를 수 있는 미디어: 그 스토리의 살아 있는 기록(최신순)의 사진 · 영상, 기록 안 순서대로.
  /// 읽지 못하면 빈 목록.
  Future<List<EntryMedia>> coverCandidates(String storyId) async {
    try {
      final entries = await _repo
          .watchEntries(EntryFilter.story(storyId))
          .first;
      return [for (final e in entries) ...e.media];
    } on Object {
      return const [];
    }
  }

  Future<void> _change(
    String id,
    Result<Story> Function(Story story) change,
  ) async {
    _begin();
    final story = _find(id);
    if (story == null) {
      emit(state.copyWith(error: DiaryFailure.notFound));
      return;
    }
    switch (change(story)) {
      case Err(:final failure):
        _fail(failure);
      case Ok(:final value):
        _settle(await _repo.updateStory(value));
    }
  }

  Story? _find(String id) =>
      [...state.open, ...state.archived].where((s) => s.id == id).firstOrNull;

  void _begin() => emit(state.copyWith(error: null, actionFailed: false));

  void _settle<T>(Result<T> result) {
    if (result case Err(:final failure)) _fail(failure);
  }

  void _fail(Failure failure) {
    final diary = switch (failure) {
      ValidationFailure(:final field) =>
        DiaryFailure.values.where((f) => f.name == field).firstOrNull,
      NotFoundFailure() => DiaryFailure.notFound,
      _ => null,
    };
    emit(
      diary == null
          ? state.copyWith(actionFailed: true)
          : state.copyWith(error: diary),
    );
  }

  @override
  Future<void> close() async {
    await _stories?.cancel();
    return super.close();
  }
}
