import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/entity/commute_settings.dart';
import '../../domain/entity/station.dart';
import '../../domain/usecase/commute_use_case.dart';
import 'commute_settings_state.dart';

@injectable
class CommuteSettingsCubit extends Cubit<CommuteSettingsState> {
  CommuteSettingsCubit(this._useCase)
    : super(const CommuteSettingsState.loading());

  final CommuteUseCase _useCase;

  Future<void> load() async {
    emit(const CommuteSettingsState.loading());
    final result = await _useCase.getSettings();
    if (isClosed) return;

    emit(switch (result) {
      Ok(value: final settings) => CommuteSettingsState.loaded(settings),
      Err(:final failure) => CommuteSettingsState.failure(failure),
    });
  }

  Future<void> setHome(Station station) => _saveWith(home: station);

  Future<void> setWork(Station station) => _saveWith(work: station);

  Future<void> _saveWith({Station? home, Station? work}) async {
    final current = state;
    if (current is! CommuteSettingsLoaded) return;

    final updated = CommuteSettings(
      home: home ?? current.settings.home,
      work: work ?? current.settings.work,
    );
    final result = await _useCase.saveSettings(updated);
    if (isClosed) return;

    emit(switch (result) {
      Ok() => CommuteSettingsState.loaded(updated),
      Err(:final failure) => CommuteSettingsState.failure(failure),
    });
  }
}
