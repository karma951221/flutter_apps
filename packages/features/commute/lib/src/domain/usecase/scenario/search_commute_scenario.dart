import 'package:core/core.dart';

import '../../entity/commute_direction.dart';
import '../../entity/commute_result.dart';
import '../../entity/origin.dart';
import '../../repository/commute_settings_repository.dart';
import '../../repository/location_repository.dart';
import '../../repository/transit_route_repository.dart';

class SearchCommuteScenario {
  const SearchCommuteScenario(
    this._settingsRepository,
    this._locationRepository,
    this._transitRouteRepository,
  );

  final CommuteSettingsRepository _settingsRepository;
  final LocationRepository _locationRepository;
  final TransitRouteRepository _transitRouteRepository;

  Future<Result<CommuteResult>> call(CommuteDirection direction) async {
    final settingsResult = await _settingsRepository.load();
    final settings = switch (settingsResult) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (settingsResult case Err(:final failure)) return Err(failure);
    if (settings == null) return const Err(Failure.unknown());
    if (!settings.isComplete) {
      return const Err(
        Failure.validation(failureCode: FailureCode.commuteNotConfigured),
      );
    }

    final departureStation = switch (direction) {
      CommuteDirection.toWork => settings.home!,
      CommuteDirection.toHome => settings.work!,
    };
    final destination = switch (direction) {
      CommuteDirection.toWork => settings.work!,
      CommuteDirection.toHome => settings.home!,
    };

    final locationResult = await _locationRepository.currentLocation(
      timeout: const Duration(seconds: 5),
    );
    final origin = switch (locationResult) {
      Ok(:final value) => Origin.currentLocation(value),
      Err() => Origin.fallbackStation(departureStation),
    };
    final originPoint = switch (origin) {
      CurrentLocationOrigin(:final point) => point,
      FallbackStationOrigin(:final station) => station.location,
    };

    final routesResult = await _transitRouteRepository.search(
      origin: originPoint,
      destination: destination.location,
    );
    return switch (routesResult) {
      Ok(:final value) => Ok(
        CommuteResult(
          direction: direction,
          origin: origin,
          destination: destination,
          routes: value,
          searchedAt: DateTime.now(),
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
