import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/dog.dart';

part 'dog_list_state.freezed.dart';

@freezed
sealed class DogListState with _$DogListState {
  const factory DogListState.loading() = DogListLoading;

  const factory DogListState.loaded(List<Dog> dogs) = DogListLoaded;

  const factory DogListState.failure(Failure failure) = DogListFailure;
}
