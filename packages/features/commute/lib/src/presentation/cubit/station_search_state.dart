import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/station.dart';

part 'station_search_state.freezed.dart';

@freezed
sealed class StationSearchState with _$StationSearchState {
  const factory StationSearchState.idle() = StationSearchIdle;

  const factory StationSearchState.searching(String query) =
      StationSearchSearching;

  const factory StationSearchState.results(
    String query,
    List<Station> stations,
  ) = StationSearchResults;

  const factory StationSearchState.failure(Failure failure) =
      StationSearchFailure;
}
