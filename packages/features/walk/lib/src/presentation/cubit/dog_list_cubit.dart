import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/dog.dart';
import '../../domain/usecase/walk_use_case.dart';
import 'dog_list_state.dart';

@injectable
class DogListCubit extends Cubit<DogListState> {
  DogListCubit(this._useCase) : super(const DogListState.loading());

  final WalkUseCase _useCase;
  StreamSubscription<Result<List<Dog>>>? _subscription;

  /// 이름순 목록을 구독한다. 다시 부르면 재구독한다(실패 후 재시도).
  Future<void> start() async {
    await _subscription?.cancel();
    if (isClosed) return;

    emit(const DogListState.loading());
    _subscription = _useCase.watchDogs().listen((result) {
      if (isClosed) return;
      emit(switch (result) {
        Ok(value: final dogs) => DogListState.loaded(dogs),
        Err(:final failure) => DogListState.failure(failure),
      });
    });
  }

  File photoFile(String relativePath) => _useCase.photoFile(relativePath);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
