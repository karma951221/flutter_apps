import 'package:injectable/injectable.dart';

import '../entity/app_theme_mode.dart';
import '../repository/theme_repository.dart';

/// theme feature 의 presentation 진입점 (규칙 ③).
abstract interface class ThemeUseCase {
  AppThemeMode loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);
}

@LazySingleton(as: ThemeUseCase)
class DefaultThemeUseCase implements ThemeUseCase {
  DefaultThemeUseCase(this._repository);

  final ThemeRepository _repository;

  @override
  AppThemeMode loadThemeMode() => _repository.loadThemeMode();

  @override
  Future<void> saveThemeMode(AppThemeMode mode) =>
      _repository.saveThemeMode(mode);
}
