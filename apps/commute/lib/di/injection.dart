import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
  externalPackageModulesBefore: [
    ExternalModule(CorePackageModule),
    ExternalModule(FeatureCommutePackageModule),
  ],
)
Future<void> configureDependencies() async {
  await getIt.init();
}
