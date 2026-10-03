import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecase/walk_use_case.dart';
import 'dog_edit_state.dart';
import 'dog_form.dart';

@injectable
class DogEditCubit extends Cubit<DogEditState> {
  DogEditCubit(this._useCase) : super(const DogEditState.loading());

  final WalkUseCase _useCase;

  DogForm? _form;
  bool _saved = false;

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

  void setBirthday(DateTime? birthday) => _update(
    (form) => DogForm(
      id: form.id,
      name: form.name,
      breed: form.breed,
      birthday: birthday,
      photoPath: form.photoPath,
      originalPhotoPath: form.originalPhotoPath,
    ),
  );

  /// 고르는 즉시 파일을 쓴다. 직전에 고른 새 파일은 지운다.
  Future<void> setPhoto(PreparedImage image) async {
    final current = state;
    if (current is! DogEditEditing || current.isSaving) return;

    final result = await _useCase.storePhoto(
      bytes: image.bytes,
      extension: image.extension,
    );
    if (isClosed) {
      if (result case Ok(value: final path)) {
        await _useCase.removePhoto(path);
      }
      return;
    }

    switch (result) {
      case Ok(value: final path):
        final form = _form!;
        final previous = form.photoPath;
        if (previous != null && previous != form.originalPhotoPath) {
          await _useCase.removePhoto(previous);
          if (isClosed) {
            await _useCase.removePhoto(path);
            return;
          }
        }
        _emitEditing(_withPhoto(form, path));
      case Err(:final failure):
        emit(DogEditState.editing(form: _form!, failure: failure));
    }
  }

  Future<void> save() async {
    final current = state;
    if (current is! DogEditEditing || current.isSaving) return;

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

  DogForm _withPhoto(DogForm form, String path) => DogForm(
    id: form.id,
    name: form.name,
    breed: form.breed,
    birthday: form.birthday,
    photoPath: path,
    originalPhotoPath: form.originalPhotoPath,
  );
}
