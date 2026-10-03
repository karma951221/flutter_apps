import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/dog.dart';
import 'dog_form.dart';

part 'dog_edit_state.freezed.dart';

@freezed
sealed class DogEditState with _$DogEditState {
  const factory DogEditState.loading() = DogEditLoading;

  const factory DogEditState.editing({
    required DogForm form,
    @Default(false) bool isSaving,
    Failure? failure,
  }) = DogEditEditing;

  const factory DogEditState.saved(Dog dog) = DogEditSaved;

  const factory DogEditState.deleted() = DogEditDeleted;

  const factory DogEditState.loadFailure(Failure failure) = DogEditLoadFailure;
}
