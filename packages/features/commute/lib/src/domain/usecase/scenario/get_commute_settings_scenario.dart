import 'package:core/core.dart';

import '../../entity/commute_settings.dart';
import '../../repository/commute_settings_repository.dart';

class GetCommuteSettingsScenario {
  const GetCommuteSettingsScenario(this._repository);

  final CommuteSettingsRepository _repository;

  Future<Result<CommuteSettings>> call() => _repository.load();
}
