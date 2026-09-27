import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/usecase/commute_use_case.dart';
import 'station_search_state.dart';

@injectable
class StationSearchCubit extends Cubit<StationSearchState> {
  StationSearchCubit(this._useCase) : super(const StationSearchState.idle());

  static const debounceDuration = Duration(milliseconds: 300);

  final CommuteUseCase _useCase;
  Timer? _debounce;
  int _generation = 0;

  void search(String query) {
    _debounce?.cancel();
    final normalized = query.trim();
    final generation = ++_generation;
    if (normalized.isEmpty) {
      emit(const StationSearchState.idle());
      return;
    }

    emit(StationSearchState.searching(normalized));
    _debounce = Timer(debounceDuration, () async {
      final result = await _useCase.searchStations(normalized);
      if (isClosed || generation != _generation) return;

      emit(switch (result) {
        Ok(value: final stations) => StationSearchState.results(
          normalized,
          stations,
        ),
        Err(:final failure) => StationSearchState.failure(failure),
      });
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
