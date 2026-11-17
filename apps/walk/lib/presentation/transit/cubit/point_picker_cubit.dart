import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/commute/repository/address_search.dart';
import '../../../domain/transit/usecase/search_stations.dart';
import '../../../domain/transit/usecase/transit_point_suggestions.dart';
import 'point_picker_state.dart';

/// 장소 고르기. 역 검색은 입력 멈춘 뒤 디바운스, 주소 검색은 사용자가 누를 때만.
@injectable
class PointPickerCubit extends Cubit<PointPickerState> {
  PointPickerCubit(
    this._stations,
    this._address,
    this._suggestions, {
    @ignoreParam this.debounce = const Duration(milliseconds: 500),
  }) : super(const PointPickerState());

  final SearchStations _stations;
  final AddressSearch _address;
  final TransitPointSuggestions _suggestions;
  final Duration debounce;

  Timer? _timer;

  /// 검색어가 바뀔 때마다 올려서 늦게 온 앞선 검색 결과를 버린다.
  int _generation = 0;

  Future<void> load() async {
    final suggestions = await _suggestions.load();
    if (isClosed) return;
    emit(state.copyWith(suggestions: suggestions));
  }

  /// IME 조합 중([composing])이거나 2글자 미만이면 검색하지 않는다.
  void queryChanged(String text, {bool composing = false}) {
    _timer?.cancel();
    final generation = ++_generation;
    final tooShort =
        text.trim().replaceAll(RegExp(r'\s+'), '').length <
        SearchStations.minLength;
    emit(
      state.copyWith(
        query: text,
        addresses: const [],
        addressSearching: false,
        stations: tooShort ? const [] : state.stations,
        searching: false,
      ),
    );
    if (composing || tooShort) return;
    _timer = Timer(debounce, () => _searchStations(text, generation));
  }

  Future<void> _searchStations(String text, int generation) async {
    if (isClosed) return;
    emit(state.copyWith(searching: true));
    var hits = state.stations;
    try {
      hits = await _stations(text);
    } on Object {
      hits = const [];
    }
    if (generation != _generation || isClosed) return;
    emit(state.copyWith(searching: false, stations: hits));
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
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
