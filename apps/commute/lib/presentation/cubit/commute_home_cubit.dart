import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/entity/commute_direction.dart';
import '../../domain/usecase/commute_use_case.dart';
import 'commute_home_state.dart';

@injectable
class CommuteHomeCubit extends Cubit<CommuteHomeState> {
  CommuteHomeCubit(this._useCase)
    : super(const CommuteHomeState.initial(CommuteDirection.toWork));

  final CommuteUseCase _useCase;
  int _generation = 0;

  CommuteDirection get _direction => switch (state) {
    CommuteHomeInitial(:final direction) ||
    CommuteHomeLoading(:final direction) ||
    CommuteHomeLoaded(:final direction) ||
    CommuteHomeFailure(:final direction) => direction,
  };

  Future<void> load() => _search(_direction);

  Future<void> setDirection(CommuteDirection direction) {
    if (direction == _direction) return Future.value();
    return _search(direction);
  }

  Future<void> refresh() => _search(_direction);

  Future<void> _search(CommuteDirection direction) async {
    final generation = ++_generation;
    emit(CommuteHomeState.loading(direction));
    final result = await _useCase.searchCommute(direction);
    if (isClosed || generation != _generation) return;

    emit(switch (result) {
      Ok(value: final commute) => CommuteHomeState.loaded(direction, commute),
      Err(:final failure) => CommuteHomeState.failure(direction, failure),
    });
  }
}
