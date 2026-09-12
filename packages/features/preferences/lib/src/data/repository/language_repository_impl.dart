import 'package:injectable/injectable.dart';

import '../../domain/entity/app_language.dart';
import '../../domain/repository/language_repository.dart';
import '../datasource/language_data_source.dart';

@LazySingleton(as: LanguageRepository)
class LanguageRepositoryImpl implements LanguageRepository {
  LanguageRepositoryImpl(this._dataSource);

  final LanguageDataSource _dataSource;

  @override
  AppLanguage loadLanguage() =>
      AppLanguage.fromCode(_dataSource.readLanguageCode());

  @override
  Future<void> saveLanguage(AppLanguage language) =>
      _dataSource.writeLanguageCode(language.code);
}
