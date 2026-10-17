import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/backup/entity/backup_import_result.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import 'dog_edit_state.dart';
import 'dog_form.dart';

@injectable
class DogEditCubit extends Cubit<DogEditState> {
  DogEditCubit(this._useCase) : super(const DogEditState.loading());

  final WalkUseCase _useCase;

  DogForm? _form;
  bool _saved = false;
  bool _importing = false;

  /// [id] 가 null 이면 신규, 아니면 불러와 채운다.
  Future<void> load(String? id) async {
    if (id == null) {
      _emitEditing(const DogForm());
      return;
    }

    emit(const DogEditState.loading());
    final result = await _useCase.getDog(id);
    if (isClosed) return;

    switch (result) {
      case Ok(value: final dog?):
        _emitEditing(DogForm.fromDog(dog));
      case Ok():
        emit(
          const DogEditState.loadFailure(
            Failure.notFound(failureCode: FailureCode.targetNotFound),
          ),
        );
      case Err(:final failure):
        emit(DogEditState.loadFailure(failure));
    }
  }

  void setName(String name) => _update((form) => form.copyWith(name: name));

  void setBreed(String breed) => _update((form) => form.copyWith(breed: breed));

  void setBirthday(DateTime? birthday) =>
      _update((form) => form.copyWith(birthday: birthday));

  /// 고르는 즉시 파일을 쓴다. 직전에 고른 새 파일은 지운다.
  Future<void> setPhoto(PreparedImage image) async {
    final current = state;
    if (current is! DogEditEditing || current.isSaving) return;

    final result = await _useCase.storePhoto(
      bytes: image.bytes,
      extension: image.extension,
    );
    // 저장·삭제·종료가 먼저 끝났으면 늦게 도착한 파일은 쓸 곳이 없다.
    if (_cannotAcceptPhoto) {
      if (result case Ok(value: final path)) {
        await _useCase.removePhoto(path);
      }
      return;
    }

    switch (result) {
      case Ok(value: final path):
        final previous = _form!.photoPath;
        if (previous != null && previous != _form!.originalPhotoPath) {
          await _useCase.removePhoto(previous);
          if (_cannotAcceptPhoto) {
            await _useCase.removePhoto(path);
            return;
          }
        }
        final form = _form!;
        _emitEditing(_withPhoto(form, path));
      case Err(:final failure):
        emit(DogEditState.editing(form: _form!, failure: failure));
    }
  }

  Future<void> save() async {
    final current = state;
    if (current is! DogEditEditing || current.isSaving || _importing) return;

    emit(DogEditState.editing(form: current.form, isSaving: true));
    final result = await _useCase.saveDog(current.form.toDraft());
    if (isClosed) return;

    switch (result) {
      case Ok(value: final dog):
        _saved = true;
        emit(DogEditState.saved(dog));
      case Err(:final failure):
        emit(DogEditState.editing(form: current.form, failure: failure));
    }
  }

  Future<void> delete() async {
    final current = state;
    if (current is! DogEditEditing || current.isSaving) return;
    final id = current.form.id;
    if (id == null) return;

    emit(DogEditState.editing(form: current.form, isSaving: true));
    final result = await _useCase.deleteDog(id);
    if (isClosed) return;

    switch (result) {
      case Ok():
        emit(const DogEditState.deleted());
      case Err(:final failure):
        emit(DogEditState.editing(form: current.form, failure: failure));
    }
  }

  File photoFile(String relativePath) => _useCase.photoFile(relativePath);

  /// 첫 실행 화면의 백업 가져오기. 폼 상태는 바꾸지 않는다. 진행 중에 다시 부르면
  /// 취소로 친다 — 파일 고르기가 두 번 뜨지 않게.
  ///
  /// [hasDogs] 는 가져온 뒤 DB 에 반려견이 한 마리라도 있는지다. 일부만 들어가고
  /// 실패했거나(`failed` · `imported(0, k)`) 이미 있던 것뿐이어도(`nothingNew`)
  /// 반려견이 있으면 첫 실행 등록 화면에 머물 이유가 없다. 취소 · 읽지 못함은 DB 를
  /// 건드리지 않았으므로 확인하지 않는다.
  Future<({BackupImportResult result, bool hasDogs})> importBackup() async {
    if (_importing) {
      return (result: const BackupImportResult.cancelled(), hasDogs: false);
    }
    _importing = true;
    try {
      final result = await _useCase.importBackup();
      return (result: result, hasDogs: await _hasDogsAfter(result));
    } finally {
      _importing = false;
    }
  }

  Future<bool> _hasDogsAfter(BackupImportResult result) async {
    if (result case BackupImportCancelled() || BackupInvalid()) return false;
    return switch (await _useCase.getDogs()) {
      Ok(value: final dogs) => dogs.isNotEmpty,
      // 목록을 못 읽으면 가져온 개수만 믿는다.
      Err() => switch (result) {
        BackupImported(:final dogs) => dogs >= 1,
        _ => false,
      },
    };
  }

  /// 저장하지 않고 닫히면 이번에 새로 고른 사진 파일을 지운다.
  @override
  Future<void> close() async {
    final form = _form;
    final photoPath = form?.photoPath;
    if (!_saved && photoPath != null && photoPath != form?.originalPhotoPath) {
      await _useCase.removePhoto(photoPath);
    }
    return super.close();
  }

  void _update(DogForm Function(DogForm form) change) {
    final current = state;
    if (current is! DogEditEditing || current.isSaving) return;
    _emitEditing(change(current.form));
  }

  void _emitEditing(DogForm form) {
    _form = form;
    emit(DogEditState.editing(form: form));
  }

  DogForm _withPhoto(DogForm form, String path) =>
      form.copyWith(photoPath: path);

  /// 저장·삭제·종료로 더는 사진을 받을 수 없는 상태인지.
  bool get _cannotAcceptPhoto {
    final current = state;
    return isClosed || current is! DogEditEditing || current.isSaving;
  }
}
