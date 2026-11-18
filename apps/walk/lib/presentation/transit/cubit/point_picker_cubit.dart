import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/commute/repository/address_search.dart';
import '../../../domain/transit/repository/transit_key_store.dart';
import '../../../domain/transit/transit_failure.dart';
import '../../../domain/transit/usecase/search_stations.dart';
import '../../../domain/transit/usecase/transit_point_suggestions.dart';
import 'point_picker_state.dart';

/// 장소 고르기. 역 검색은 입력 멈춘 뒤 디바운스, 주소 검색은 사용자가 누를 때만.
/// 키가 저장 · 삭제되면 키 때문에 실패한 역 검색을 다시 한다.
@injectable
class PointPickerCubit extends Cubit<PointPickerState> {
  PointPickerCubit(
    this._stations,
    this._address,
    this._suggestions,
    TransitKeyStore keys, {
    @ignoreParam this.debounce = const Duration(milliseconds: 500),
    @ignoreParam this.composingDebounce = const Duration(milliseconds: 900),
  }) : super(const PointPickerState()) {
    _keySub = keys.changes.listen((_) => _onKeyChanged());
  }

  final SearchStations _stations;
  final AddressSearch _address;
  final TransitPointSuggestions _suggestions;
  final Duration debounce;

  /// IME 조합 중일 때의 디바운스. 조합이 끝나지 않는 키보드도 있어 검색은 하되 더 기다린다.
  final Duration composingDebounce;

  late final StreamSubscription<void> _keySub;

  Timer? _timer;

  /// 검색어가 바뀔 때마다 올려서 늦게 온 앞선 검색 결과를 버린다.
  int _generation = 0;

  Future<void> load() async {
    final suggestions = await _suggestions.load();
    if (isClosed) return;
    emit(state.copyWith(suggestions: suggestions));
  }

  /// 2글자 미만이면 검색하지 않는다. IME 조합 중([composing])이면 [composingDebounce] 만큼 기다린다.
  void queryChanged(String text, {bool composing = false}) {
    _timer?.cancel();
    final generation = ++_generation;
    final tooShort = _tooShort(text);
    emit(
      state.copyWith(
        query: text,
        addresses: const [],
        addressSearching: false,
        stations: tooShort ? const [] : state.stations,
        searching: false,
        stationFailure: null,
      ),
    );
    if (tooShort) return;
    _timer = Timer(
      composing ? composingDebounce : debounce,
      () => _searchStations(text, generation),
    );
  }

  /// 키보드 검색 버튼. 디바운스를 건너뛰고 역 검색만 바로 한다(주소는 그 줄을 누를 때만).
  void submitted(String text) {
    if (text != state.query) queryChanged(text);
    _timer?.cancel();
    if (_tooShort(text)) return;
    unawaited(_searchStations(text, _generation));
  }

  bool _tooShort(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), '').length <
      SearchStations.minLength;

  void _onKeyChanged() {
    if (isClosed) return;
    switch (state.stationFailure) {
      case TransitMissingKey() || TransitKeyRejected():
        _timer?.cancel();
        unawaited(_searchStations(state.query, ++_generation));
      default:
        return;
    }
  }

  Future<void> _searchStations(String text, int generation) async {
    if (isClosed) return;
    emit(state.copyWith(searching: true, stationFailure: null));
    var hits = state.stations;
    TransitFailure? failure;
    try {
      hits = await _stations(text);
    } on Object catch (e) {
      hits = const [];
      failure = e is TransitFailure
          ? e
          : TransitFailure.unexpected(describeError(e));
    }
    if (generation != _generation || isClosed) return;
    emit(
      state.copyWith(searching: false, stations: hits, stationFailure: failure),
    );
  }

  /// 주소 · 장소 이름 검색. 사용자가 누를 때만 부른다.
  Future<void> searchAddress() async {
    final text = state.query.trim();
    if (text.isEmpty || state.addressSearching) return;
    final generation = _generation;
    emit(state.copyWith(addressSearching: true));
    var found = state.addresses;
    try {
      found = await _address.search(text);
    } on Object {
      found = const [];
    }
    if (generation != _generation || isClosed) return;
    emit(state.copyWith(addressSearching: false, addresses: found));
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _keySub.cancel();
    return super.close();
  }
}
