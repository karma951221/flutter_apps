import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'walk_edit_form.dart';

part 'walk_edit_state.freezed.dart';

@freezed
sealed class WalkEditState with _$WalkEditState {
  const factory WalkEditState.loading() = WalkEditLoading;

  const factory WalkEditState.editing({
    required WalkEditForm form,
    @Default(false) bool isSaving,
    Failure? failure,
  }) = WalkEditEditing;

  const factory WalkEditState.saved(String walkId) = WalkEditSaved;

  const factory WalkEditState.discarded() = WalkEditDiscarded;

  const factory WalkEditState.loadFailure(Failure failure) =
      WalkEditLoadFailure;
}
