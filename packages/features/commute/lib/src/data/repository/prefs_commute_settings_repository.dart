import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entity/commute_settings.dart';
import '../../domain/entity/station.dart';
import '../../domain/repository/commute_settings_repository.dart';
import '../../domain/repository/station_repository.dart';

@LazySingleton(as: CommuteSettingsRepository)
class PrefsCommuteSettingsRepository implements CommuteSettingsRepository {
  PrefsCommuteSettingsRepository(this._preferences, this._stationRepository);

  static const homeStationKey = 'commute.home_station_id';
  static const workStationKey = 'commute.work_station_id';

  final SharedPreferences _preferences;
  final StationRepository _stationRepository;

  @override
  Future<Result<CommuteSettings>> load() async {
    final homeResult = await _find(_preferences.getString(homeStationKey));
    if (homeResult case Err(:final failure)) return Err(failure);
    final workResult = await _find(_preferences.getString(workStationKey));
    if (workResult case Err(:final failure)) return Err(failure);
    return Ok(
      CommuteSettings(
        home: (homeResult as Ok<Station?>).value,
        work: (workResult as Ok<Station?>).value,
      ),
    );
  }

  @override
  Future<Result<void>> save(CommuteSettings settings) async {
    try {
      await _saveId(homeStationKey, settings.home?.id);
      await _saveId(workStationKey, settings.work?.id);
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  Future<Result<Station?>> _find(String? id) => id == null
      ? Future.value(const Ok(null))
      : _stationRepository.findById(id);

  Future<void> _saveId(String key, String? id) async {
    if (id == null) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, id);
    }
  }
}
