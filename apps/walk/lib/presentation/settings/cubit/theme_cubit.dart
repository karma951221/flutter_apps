import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/settings/entity/app_settings.dart';
import '../../../domain/settings/repository/settings_repository.dart';

/// 앱 전체 테마. `MaterialApp` 위에 둔다. 처음 값은 동기 [SettingsRepository.load]
/// 라 첫 프레임부터 저장된 테마로 뜬다.
class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit(this._repository) : super(_repository.load().themeMode);

  final SettingsRepository _repository;

  /// 즉시 반영하고 저장한다.
  Future<void> select(AppThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _repository.save(_repository.load().copyWith(themeMode: mode));
  }
}
