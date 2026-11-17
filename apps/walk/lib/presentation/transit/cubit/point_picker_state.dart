import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/commute/repository/address_search.dart';
import '../../../domain/transit/entity/station_hit.dart';
import '../../../domain/transit/transit_failure.dart';
import '../../../domain/transit/usecase/transit_point_suggestions.dart';

part 'point_picker_state.freezed.dart';

/// 장소 고르기 화면 상태 — 검색어 · 역 검색 결과 · 주소 검색 결과 · 후보.
@freezed
class PointPickerState with _$PointPickerState {
  @override
  final String query;

  /// 역 · 정류장 검색 중.
  @override
  final bool searching;

  @override
  final List<StationHit> stations;

  @override
  final List<PlaceCandidate> addresses;

  /// 사용자가 눌러 시작한 주소 검색 중.
  @override
  final bool addressSearching;

  /// 역 검색이 실패한 이유. 새 검색어를 치면 지운다.
  @override
  final TransitFailure? stationFailure;

  @override
  final TransitSuggestions? suggestions;

  const PointPickerState({
    this.query = '',
    this.searching = false,
    this.stations = const [],
    this.addresses = const [],
    this.addressSearching = false,
    this.stationFailure,
    this.suggestions,
  });
}
