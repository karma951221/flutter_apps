import 'package:injectable/injectable.dart';

import '../../domain/entity/app_theme_mode.dart';
import '../../domain/repository/theme_repository.dart';
import '../datasource/theme_data_source.dart';

@LazySingleton(as: ThemeRepository)
class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl(this._dataSource);

  final ThemeDataSource _dataSource;

  @override
  AppThemeMode loadThemeMode() =>
      AppThemeMode.fromCode(_dataSource.readThemeCode());

  @override
  Future<void> saveThemeMode(AppThemeMode mode) =>
      _dataSource.writeThemeCode(mode.code);
}
