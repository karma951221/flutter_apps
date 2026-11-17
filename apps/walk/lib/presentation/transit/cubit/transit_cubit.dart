import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/diary/location/place_source.dart';
import '../../../domain/transit/entity/transit_point.dart';
import '../../../domain/transit/repository/recent_points.dart';
import '../../../domain/transit/repository/transit_key_store.dart';
import '../../../domain/transit/transit_failure.dart';
import '../../../domain/transit/usecase/find_transit_routes.dart';
import 'transit_state.dart';

/// 길찾기 탭. 출발 · 도착이 모두 차면 자동으로 조회한다.
/// 키가 저장 · 삭제되면 키 때문에 실패한 조회를 다시 한다.
@injectable
class TransitCubit extends Cubit<TransitState> {
  TransitCubit(
    this._find,
    this._placeSource,
    this._recent,
    TransitKeyStore keys,
  ) : super(const TransitState()) {
    _keySub = keys.changes.listen((_) => _onKeyChanged());
  }

  final FindTransitRoutes _find;
  final PlaceSource _placeSource;
  final RecentPoints _recent;
  late final StreamSubscription<void> _keySub;

  /// 요청 번호. 새 요청이 시작되면 올려서 앞선 요청의 결과를 버린다.
  int _generation = 0;

  /// 출발을 현재 위치로 채워 본다. 못 얻으면 `locationFailed`, 출발은 비운 채.
  Future<void> start() async {
    if (state.locating) return;
    emit(state.copyWith(locating: true, locationFailed: false));
    TransitPoint? point;
    try {
      final loc = await _placeSource.current();
      final lat = loc?.lat;
      final lng = loc?.lng;
      if (lat != null && lng != null) {
        point = TransitPoint(
          lat: lat,
          lng: lng,
          label: '',
          source: TransitPointSource.currentLocation,
        );
      }
    } on Object {
      point = null;
    }
    if (isClosed) return;
    if (point == null) {
      emit(state.copyWith(locating: false, locationFailed: true));
      return;
    }
    // 위치를 찾는 동안 사용자가 출발을 직접 골랐으면 그대로 둔다.
    if (state.from != null) {
      emit(state.copyWith(locating: false));
      return;
    }
    emit(state.copyWith(locating: false, from: point));
    _queryIfReady();
  }

  Future<void> setFrom(TransitPoint point) async {
    emit(state.copyWith(from: point, locationFailed: false));
    _queryIfReady();
    await _remember(point);
  }

  Future<void> setTo(TransitPoint point) async {
    emit(state.copyWith(to: point));
    _queryIfReady();
    await _remember(point);
  }

  /// 빈 칸에 채운다. 출발 → 도착 순, 둘 다 차 있으면 도착을 바꾼다.
  Future<void> fillEmpty(TransitPoint point) =>
      state.from == null ? setFrom(point) : setTo(point);

  void swap() {
    emit(state.copyWith(from: state.to, to: state.from));
    _queryIfReady();
  }

  /// 캐시를 건너뛰고 다시 조회한다.
  void refresh() => _queryIfReady(refresh: true);

  void _onKeyChanged() {
    if (isClosed) return;
    final retry = switch (state.status) {
      TransitFailed(failure: TransitMissingKey() || TransitKeyRejected()) =>
        true,
      TransitIdle() => state.from != null && state.to != null,
      _ => false,
    };
    if (retry) _queryIfReady();
  }

  Future<void> _remember(TransitPoint point) async {
    if (point.source == TransitPointSource.currentLocation) return;
    try {
      await _recent.add(point);
    } on Object {
      // 최근 장소 저장 실패는 길찾기에 영향을 주지 않는다.
    }
  }

  void _queryIfReady({bool refresh = false}) {
    final from = state.from;
    final to = state.to;
    if (from == null || to == null) {
      _generation++;
      if (state.status is! TransitIdle) {
        emit(state.copyWith(status: const TransitStatus.idle()));
      }
      return;
    }
    _run(from, to, refresh: refresh);
  }

  Future<void> _run(
    TransitPoint from,
    TransitPoint to, {
    required bool refresh,
  }) async {
    final generation = ++_generation;
    emit(state.copyWith(status: const TransitStatus.loading()));
    TransitStatus next;
    try {
      next = TransitStatus.loaded(await _find(from, to, refresh: refresh));
    } on Object catch (e) {
      next = TransitStatus.failure(
        e is TransitFailure
            ? e
            : TransitFailure.server(e.runtimeType.toString()),
      );
    }
    if (generation != _generation || isClosed) return;
    emit(state.copyWith(status: next));
  }

  @override
  Future<void> close() async {
    await _keySub.cancel();
    return super.close();
  }
}
