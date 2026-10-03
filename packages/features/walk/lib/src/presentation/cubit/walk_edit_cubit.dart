import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/dog.dart';
import '../../domain/entity/tracker_state.dart';
import '../../domain/entity/walk.dart';
import '../../domain/usecase/walk_use_case.dart';
import 'walk_edit_form.dart';
import 'walk_edit_state.dart';

@injectable
class WalkEditCubit extends Cubit<WalkEditState> {
  WalkEditCubit(this._useCase) : super(const WalkEditState.loading());

  final WalkUseCase _useCase;

  WalkEditForm? _form;

  /// `saved` · `discarded` 로 끝났다 — 사진 파일이 산책에 넘어갔거나 이미 지워졌다.
  bool _done = false;

  static const _notFound = Failure.notFound(
    failureCode: FailureCode.walkNotFound,
  );

  /// 종료된 추적 세션으로 저장 폼을 만든다. 세션이 없으면 `loadFailure`.
  Future<void> loadNew() async {
    emit(const WalkEditState.loading());
    final tracker = _useCase.trackerState;
    if (tracker is! TrackerFinished) {
      emit(const WalkEditState.loadFailure(_notFound));
      return;
    }

    final session = tracker.session;
    final result = await _useCase.getDogs();
    if (isClosed) return;

    switch (result) {
      case Ok(value: final dogs):
        _emitEditing(
          WalkEditForm(
            dogs: dogs,
            selectedDogIds: {
              for (final dog in dogs)
                if (session.dogIds.contains(dog.id)) dog.id,
            },
            session: session,
          ),
        );
      case Err(:final failure):
        emit(WalkEditState.loadFailure(failure));
    }
  }

  Future<void> loadExisting(String id) async {
    emit(const WalkEditState.loading());
    final (walkResult, dogsResult) = await (
      _useCase.getWalk(id),
      _useCase.getDogs(),
    ).wait;
    if (isClosed) return;

    switch ((walkResult, dogsResult)) {
      case (Err(:final failure), _) || (_, Err(:final failure)):
        emit(WalkEditState.loadFailure(failure));
      case (Ok(value: null), _):
        emit(const WalkEditState.loadFailure(_notFound));
      case (Ok<Walk?>(value: final walk?), Ok<List<Dog>>(value: final dogs)):
        _emitEditing(
          WalkEditForm(
            dogs: dogs,
            selectedDogIds: {for (final dog in walk.dogs) dog.id},
            memo: walk.memo ?? '',
            photoPaths: [for (final photo in walk.photos) photo.path],
            existing: walk,
          ),
        );
    }
  }

  File photoFile(String relativePath) => _useCase.photoFile(relativePath);

  void toggleDog(String id) => _update((form) {
    final next = {...form.selectedDogIds};
    if (!next.remove(id)) next.add(id);
    return form.copyWith(selectedDogIds: next);
  });

  void setMemo(String memo) => _update((form) => form.copyWith(memo: memo));

  /// 고르는 즉시 한 장씩 파일에 쓴다. 넘치는 몫은 버리고, 실패한 장은 건너뛴다.
  Future<void> addPhotos(List<PreparedImage> images) async {
    final start = state;
    if (start is! WalkEditEditing || start.isSaving) return;
    // 같은 실패가 연달아 나도 리스너가 다시 듣도록 먼저 비운다.
    if (start.failure != null) _emitEditing(start.form);

    final room = WalkEditForm.maxPhotos - start.form.photoPaths.length;
    for (final image in images.take(room < 0 ? 0 : room)) {
      final result = await _useCase.storePhoto(
        bytes: image.bytes,
        extension: image.extension,
      );

      // await 사이에 닫혔거나 저장·버리기가 시작됐을 수 있다 — 방금 쓴 파일이 새지 않게 한다.
      final current = state;
      final editing =
          !isClosed &&
              current is WalkEditEditing &&
              !current.isSaving &&
              !current.form.isPhotoLimitReached
          ? current
          : null;
      switch (result) {
        case Ok(value: final path):
          if (editing == null) {
            await _useCase.removePhoto(path);
            return;
          }
          _emitEditing(
            editing.form.copyWith(
              photoPaths: [...editing.form.photoPaths, path],
            ),
          );
        case Err(:final failure):
          if (editing == null) return;
          emit(WalkEditState.editing(form: editing.form, failure: failure));
      }
    }
  }

  /// 목록에서 뺀다. 이번 폼에서 쓴 파일이면 바로 지우고, 기존 사진 파일은
  /// 저장 성공 뒤 `UpdateWalkScenario` 가 지운다.
  Future<void> removePhoto(int index) async {
    final current = state;
    if (current is! WalkEditEditing || current.isSaving) return;
    final form = current.form;
    if (index < 0 || index >= form.photoPaths.length) return;

    final path = form.photoPaths[index];
    final wasAdded = form.addedPhotoPaths.contains(path);
    _emitEditing(
      form.copyWith(photoPaths: [...form.photoPaths]..removeAt(index)),
    );
    if (wasAdded) await _useCase.removePhoto(path);
  }

  Future<void> save() async {
    final current = state;
    if (current is! WalkEditEditing || current.isSaving) return;

    final form = current.form;
    emit(WalkEditState.editing(form: form, isSaving: true));
    final result = form.isNew
        ? await _useCase.saveWalk(form.toDraft())
        : await _useCase.updateWalk(form.toUpdate());
    if (isClosed) return;

    switch (result) {
      case Ok(value: final walk):
        _done = true;
        emit(WalkEditState.saved(walk.id));
      case Err(:final failure):
        emit(WalkEditState.editing(form: form, failure: failure));
    }
  }

  /// 신규 폼 버리기 — 세션과 이번에 붙인 사진을 지운다. 수정 모드에서는 하지 않는다:
  /// `discardWalk` 의 `tracker.clear()` 가 저장 대기 중인 다른 세션을 지울 수 있다.
  Future<void> discard() async {
    final current = state;
    if (current is! WalkEditEditing || current.isSaving) return;
    final form = current.form;
    if (!form.isNew) return;

    emit(WalkEditState.editing(form: form, isSaving: true));
    await _useCase.discardWalk(photoPaths: form.addedPhotoPaths);
    _done = true;
    if (isClosed) return;
    emit(const WalkEditState.discarded());
  }

  /// 저장 · 버리기 없이 닫히면 이번 폼에서 쓴 사진을 지운다. 신규 모드라도
  /// `tracker.clear()` 는 하지 않는다 — 세션은 피드 배너로 다시 온다.
  /// 저장이 진행 중에 닫히면 결과를 알 수 없어 지우지 않는다(고아 파일은 감수).
  @override
  Future<void> close() async {
    final form = _form;
    final current = state;
    final saving = current is WalkEditEditing && current.isSaving;
    if (!_done && !saving && form != null) {
      for (final path in form.addedPhotoPaths) {
        await _useCase.removePhoto(path);
      }
    }
    return super.close();
  }

  void _update(WalkEditForm Function(WalkEditForm form) change) {
    final current = state;
    if (current is! WalkEditEditing || current.isSaving) return;
    _emitEditing(change(current.form));
  }

  void _emitEditing(WalkEditForm form) {
    _form = form;
    emit(WalkEditState.editing(form: form));
  }
}
