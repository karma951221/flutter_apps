import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
  externalPackageModulesBefore: [
    ExternalModule(CorePackageModule),
    ExternalModule(FeatureWalkPackageModule),
  ],
)
Future<void> configureDependencies() async {
  await getIt.init();
}
