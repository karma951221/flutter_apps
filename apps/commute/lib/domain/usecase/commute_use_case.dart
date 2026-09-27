import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entity/commute_direction.dart';
import '../entity/commute_result.dart';
import '../entity/commute_settings.dart';
import '../entity/station.dart';
import '../repository/commute_settings_repository.dart';
import '../repository/location_repository.dart';
import '../repository/station_repository.dart';
import '../repository/transit_route_repository.dart';
import 'scenario/get_commute_settings_scenario.dart';
import 'scenario/save_commute_settings_scenario.dart';
import 'scenario/search_commute_scenario.dart';
import 'scenario/search_stations_scenario.dart';

abstract interface class CommuteUseCase {
  Future<Result<CommuteSettings>> getSettings();

  Future<Result<void>> saveSettings(CommuteSettings settings);

  Future<Result<List<Station>>> searchStations(String query);

  Future<Result<CommuteResult>> searchCommute(CommuteDirection direction);
}

@LazySingleton(as: CommuteUseCase)
class DefaultCommuteUseCase implements CommuteUseCase {
  DefaultCommuteUseCase(
    this._transitRouteRepository,
    this._locationRepository,
    this._stationRepository,
    this._settingsRepository,
  );

  final TransitRouteRepository _transitRouteRepository;
  final LocationRepository _locationRepository;
  final StationRepository _stationRepository;
  final CommuteSettingsRepository _settingsRepository;

  @override
  Future<Result<CommuteSettings>> getSettings() =>
      GetCommuteSettingsScenario(_settingsRepository)();

  @override
  Future<Result<void>> saveSettings(CommuteSettings settings) =>
      SaveCommuteSettingsScenario(_settingsRepository)(settings);

  @override
  Future<Result<List<Station>>> searchStations(String query) =>
      SearchStationsScenario(_stationRepository)(query);

  @override
  Future<Result<CommuteResult>> searchCommute(CommuteDirection direction) =>
      SearchCommuteScenario(
        _settingsRepository,
        _locationRepository,
        _transitRouteRepository,
      )(direction);
}
