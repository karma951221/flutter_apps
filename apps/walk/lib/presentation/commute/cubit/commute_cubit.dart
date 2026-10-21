import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/commute/commute_failure.dart';
import '../../../domain/commute/entity/commute_direction.dart';
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

  /// 방향을 바꾸고 이전 결과를 비운다.
  void setDirection(CommuteDirection direction) {
    emit(
      state.copyWith(direction: direction, status: const CommuteStatus.idle()),
    );
  }

  Future<void> query() async {
    if (_busy) return;
    _busy = true;
    emit(state.copyWith(status: const CommuteStatus.loading()));
    try {
      final result = await _useCase.query(state.direction);
      if (!isClosed) {
        emit(state.copyWith(status: CommuteStatus.loaded(result)));
      }
    } on Object catch (e) {
      if (!isClosed) {
        emit(state.copyWith(status: CommuteStatus.failure(_wrap(e))));
      }
    } finally {
      _busy = false;
    }
  }

  /// 결과가 있을 때만 동작한다. 실패하면 `failure` — 다시 조회할 수 있다.
  Future<void> selectRoute(TransitRoute route) async {
    final current = state.status;
    if (_busy || current is! CommuteLoaded) return;
    _busy = true;
    try {
      final result = await _useCase.selectRoute(current.result, route);
      if (!isClosed) {
        emit(state.copyWith(status: CommuteStatus.loaded(result)));
      }
    } on Object catch (e) {
      if (!isClosed) {
        emit(state.copyWith(status: CommuteStatus.failure(_wrap(e))));
      }
    } finally {
      _busy = false;
    }
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

  Future<void> _save(Place place) async {
    await _useCase.savePlace(place);
    if (isClosed) return;
    emit(switch (place.kind) {
      PlaceKind.home => state.copyWith(home: place),
      PlaceKind.work => state.copyWith(work: place),
    });
  }

  static CommuteFailure _wrap(Object e) =>
      e is CommuteFailure ? e : const CommuteFailure.server('');
}
