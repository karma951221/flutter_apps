import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/commute/commute_failure.dart';
import '../../../domain/commute/entity/commute_direction.dart';
import '../../../domain/commute/entity/commute_result.dart';
import '../../../domain/commute/entity/place.dart';
import '../../../domain/commute/entity/transit_route.dart';
import '../../../domain/commute/repository/address_search.dart';
import '../../../domain/commute/usecase/commute_use_case.dart';
import '../../../domain/diary/location/place_source.dart';
import 'commute_state.dart';

/// 통근 탭. 네트워크는 [query] · [selectRoute] 를 부를 때만 쓴다(자동 새로고침 없음).
class CommuteCubit extends Cubit<CommuteState> {
  CommuteCubit(this._useCase, this._placeSource, this._search, Clock clock)
    : super(
        CommuteState(
          direction: CommuteDirection.defaultAt(clock.now()),
          home: _useCase.place(PlaceKind.home),
          work: _useCase.place(PlaceKind.work),
        ),
      );

  final CommuteUseCase _useCase;
  final PlaceSource _placeSource;
  final AddressSearch _search;

  /// 조회 · 경로 바꾸기가 진행 중이면 연타를 무시한다.
  bool _busy = false;

  /// 요청 번호. 방향을 바꾸면 올려서 진행 중이던 요청의 결과를 버린다.
  int _token = 0;

  /// 방향을 바꾸고 이전 결과를 비운다. 진행 중이던 요청은 결과를 버리고,
  /// 새 방향의 조회를 막지 않는다.
  void setDirection(CommuteDirection direction) {
    _token++;
    _busy = false;
    emit(
      state.copyWith(direction: direction, status: const CommuteStatus.idle()),
    );
  }

  Future<void> query() async {
    if (_busy) return;
    await _run(() => _useCase.query(state.direction), showLoading: true);
  }

  /// 결과가 있을 때만 동작한다. 실패하면 `failure` — 다시 조회할 수 있다.
  Future<void> selectRoute(TransitRoute route) async {
    final current = state.status;
    if (_busy || current is! CommuteLoaded) return;
    await _run(() => _useCase.selectRoute(current.result, route));
  }

  Future<void> _run(
    Future<CommuteResult> Function() call, {
    bool showLoading = false,
  }) async {
    _busy = true;
    final token = ++_token;
    if (showLoading) {
      emit(state.copyWith(status: const CommuteStatus.loading()));
    }
    CommuteStatus next;
    try {
      next = CommuteStatus.loaded(await call());
    } on Object catch (e) {
      next = CommuteStatus.failure(_wrap(e));
    }
    if (token != _token) return; // 방향이 바뀌었다 — 옛 요청의 결과는 버린다.
    _busy = false;
    if (!isClosed) emit(state.copyWith(status: next));
  }

  /// 현재 위치를 [kind] 로 저장한다. 위치를 못 얻으면 false(저장 없음).
  Future<bool> useCurrentLocation(PlaceKind kind) async {
    if (state.locating) return false;
    emit(state.copyWith(locating: true));
    try {
      final loc = await _placeSource.current();
      final lat = loc?.lat;
      final lng = loc?.lng;
      if (loc == null || lat == null || lng == null) return false;
      final label =
          loc.placeName ??
          '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
      await _save(Place(kind: kind, lat: lat, lng: lng, label: label));
      return true;
    } on Object {
      return false;
    } finally {
      if (!isClosed) {
        emit(state.copyWith(locating: false));
      }
    }
  }

  Future<List<PlaceCandidate>> searchAddress(String query) =>
      _search.search(query);

  Future<void> choosePlace(PlaceKind kind, PlaceCandidate candidate) => _save(
    Place(
      kind: kind,
      lat: candidate.lat,
      lng: candidate.lng,
      label: candidate.label,
    ),
  );

  /// 장소가 바뀌면 이전 결과는 맞지 않는다 — 진행 중이던 요청도 버리고 idle 로.
  Future<void> _save(Place place) async {
    await _useCase.savePlace(place);
    if (isClosed) return;
    _token++;
    _busy = false;
    final saved = switch (place.kind) {
      PlaceKind.home => state.copyWith(home: place),
      PlaceKind.work => state.copyWith(work: place),
    };
    emit(saved.copyWith(status: const CommuteStatus.idle()));
  }

  static CommuteFailure _wrap(Object e) =>
      e is CommuteFailure ? e : CommuteFailure.server(e.runtimeType.toString());
}
