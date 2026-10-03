import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecase/walk_use_case.dart';
import 'walk_detail_state.dart';

@injectable
class WalkDetailCubit extends Cubit<WalkDetailState> {
  WalkDetailCubit(this._useCase) : super(const WalkDetailState.loading());

  final WalkUseCase _useCase;

  /// 산책과 경로를 함께 읽는다. 이미 내용이 떠 있으면(수정에서 돌아온 재조회)
  /// 로딩 표시로 화면을 비우지 않고 조용히 바꾼다.
  Future<void> load(String id) async {
    if (state is! WalkDetailLoaded && state is! WalkDetailDeleting) {
      emit(const WalkDetailState.loading());
    }
    final (walkResult, trackResult) = await (
      _useCase.getWalk(id),
      _useCase.getWalkTrack(id),
    ).wait;
    if (isClosed) return;

    switch ((walkResult, trackResult)) {
      case (Err(:final failure), _) || (_, Err(:final failure)):
        emit(WalkDetailState.failure(failure));
      case (Ok(value: null), _):
        emit(
          const WalkDetailState.failure(
            Failure.notFound(failureCode: FailureCode.walkNotFound),
          ),
        );
      case (Ok(value: final walk?), Ok(value: final track)):
        emit(WalkDetailState.loaded(walk: walk, track: track));
    }
  }

  Future<void> delete() async {
    final current = state;
    if (current is! WalkDetailLoaded) return;

    emit(WalkDetailState.deleting(walk: current.walk, track: current.track));
    final result = await _useCase.deleteWalk(current.walk.id);
    if (isClosed) return;

    switch (result) {
      case Ok():
        emit(const WalkDetailState.deleted());
      case Err(:final failure):
        emit(
          WalkDetailState.loaded(
            walk: current.walk,
            track: current.track,
            failure: failure,
          ),
        );
    }
  }

  File photoFile(String relativePath) => _useCase.photoFile(relativePath);
}
