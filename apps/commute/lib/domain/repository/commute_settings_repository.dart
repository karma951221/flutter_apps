import 'package:core/core.dart';

import '../entity/commute_settings.dart';

abstract interface class CommuteSettingsRepository {
  Future<Result<CommuteSettings>> load();

  Future<Result<void>> save(CommuteSettings settings);
}
