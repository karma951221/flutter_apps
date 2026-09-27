import 'package:core/core.dart';

import '../../entity/commute_settings.dart';
import '../../repository/commute_settings_repository.dart';

class SaveCommuteSettingsScenario {
  const SaveCommuteSettingsScenario(this._repository);

  final CommuteSettingsRepository _repository;

  Future<Result<void>> call(CommuteSettings settings) =>
      _repository.save(settings);
}
