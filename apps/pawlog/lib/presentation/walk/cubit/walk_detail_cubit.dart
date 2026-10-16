import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/export/policy/gpx_encoder.dart';
import '../../../domain/export/repository/walk_file_sharer.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import 'walk_detail_state.dart';
import 'walk_export_result.dart';

@injectable
class WalkDetailCubit extends Cubit<WalkDetailState> {
  WalkDetailCubit(this._useCase, this._sharer)
    : super(const WalkDetailState.loading());

  static const gpxMimeType = 'application/gpx+xml';

  final WalkUseCase _useCase;
  final WalkFileSharer _sharer;

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

  /// 떠 있는 산책을 GPX 로 만들어 공유 시트로 넘긴다. 상태는 바꾸지 않고
  /// 결과만 돌려준다 — 스낵바는 페이지가 띄운다.
  Future<WalkExportResult> exportGpx() async {
    final current = state;
    if (current is! WalkDetailLoaded) {
      return const WalkExportResult.failed(Failure.unknown());
    }
    if (current.track.isEmpty) return const WalkExportResult.noRoute();

    final walk = current.walk;
    final result = await _sharer.shareFile(
      fileName: GpxEncoder.fileName(walk.startedAt),
      contents: GpxEncoder.encode(
        name: walk.dogs.map((dog) => dog.name).join(', '),
        description: walk.memo,
        startedAt: walk.startedAt,
        points: current.track,
      ),
      mimeType: gpxMimeType,
    );
    return switch (result) {
      Ok() => const WalkExportResult.shared(),
      Err(:final failure) => WalkExportResult.failed(failure),
    };
  }

  File photoFile(String relativePath) => _useCase.photoFile(relativePath);
}
