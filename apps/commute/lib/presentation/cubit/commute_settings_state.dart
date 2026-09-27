import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/commute_settings.dart';

part 'commute_settings_state.freezed.dart';

@freezed
sealed class CommuteSettingsState with _$CommuteSettingsState {
  const factory CommuteSettingsState.loading() = CommuteSettingsLoading;

  const factory CommuteSettingsState.loaded(CommuteSettings settings) =
      CommuteSettingsLoaded;

  const factory CommuteSettingsState.failure(Failure failure) =
      CommuteSettingsFailure;
}
